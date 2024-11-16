require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :polynomially_longer, attempts: Float::INFINITY

    def perform(govbox_message)
      processed_message = ::Message.where(type: [nil, 'Message']).where(uuid: govbox_message.message_id).joins(:thread).where(thread: { box_id: govbox_message.box.id }).take

      ActiveRecord::Base.transaction do
        destroy_associated_message_draft(govbox_message)

        message = Govbox::Message.create_message_with_thread!(govbox_message)

        mark_delivery_notification_authorized(govbox_message)
        mark_associated_delivery_notification_authorized(govbox_message)
        collapse_referenced_outbox_message(message)
        create_message_relations(message)
        download_upvs_form_related_documents(message)
      end unless processed_message
    end

    private

    def destroy_associated_message_draft(govbox_message)
      message_draft = Upvs::MessageDraft.where(uuid: govbox_message.message_id).joins(:thread).where(thread: { box_id: govbox_message.box.id }).take
      message_draft&.destroy
    end

    def mark_delivery_notification_authorized(govbox_message)
      return unless govbox_message.delivery_notification

      authorized_govbox_message = Govbox::Message.where(message_id: govbox_message.delivery_notification['consignment']['message_id'])
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if authorized_govbox_message
        delivery_notification_message = ::Message.where(uuid: govbox_message.message_id)
                                                 .joins(:thread).where(thread: { box_id: govbox_message.box.id }).take
        mark_delivery_notificiation_message_authorized(delivery_notification_message) if delivery_notification_message
      elsif govbox_message.delivery_notification['consignment']['type'] == 'Doc.GeneralAgendaReport'
        Govbox::ProcessUnauthorizedDeliveryNotificationJob.set(wait_until: Time.parse(govbox_message.delivery_notification['delivery_period_end_at']))
                                                          .perform_later(govbox_message) if Time.parse(govbox_message.delivery_notification['delivery_period_end_at']) > Time.now
      end
    end

    def mark_associated_delivery_notification_authorized(govbox_message)
      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id)
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.where(uuid: delivery_notification_govbox_message.message_id)
                                                 .joins(:thread).where(thread: { box_id: govbox_message.box.id }).take
        mark_delivery_notificiation_message_authorized(delivery_notification_message) if delivery_notification_message
      end
    end

    def create_message_relations(message)
      related_messages = ::Message.where("metadata ->> 'reference_id' = ?", message.uuid).joins(:thread)
                                .where(thread: { box_id: message.thread.box_id })

      related_messages.each do |related_message|
        message.message_relations.find_or_create_by!(
          related_message: related_message
        )
      end

      main_message = ::Message.where(uuid: message.metadata['reference_id']).joins(:thread)
                                .where(thread: { box_id: message.thread.box_id }).take

      main_message.message_relations.find_or_create_by!(
        related_message: message
      ) if main_message
    end

    def collapse_referenced_outbox_message(message)
      return if message.collapsed?

      if message.outbox?
        # TODO change .where(collapsed: false) to .where(hidden: true)
        referring_messages = message.thread.messages.inbox.where("metadata ->> 'reference_id' = ?", message.uuid).where(collapsed: false)
        message.update(collapsed: true) if referring_messages.any?
      else
        message.thread.messages.outbox.where(uuid: message.metadata["reference_id"]).take&.update(
          collapsed: true
        )
      end
    end

    def mark_delivery_notificiation_message_authorized(delivery_notification_message)
      delivery_notification_message.collapsed = true
      delivery_notification_message.metadata['authorized'] = true
      delivery_notification_message.save!

      Govbox::Message.remove_delivery_notification_tag(delivery_notification_message)
    end

    def download_upvs_form_related_documents(message)
      message.objects.each do |message_object|
        next if message_object.form&.related_documents.present?

        upvs_form = message_object.find_or_create_form
        ::Upvs::DownloadFormRelatedDocumentsJob.perform_later(upvs_form) if upvs_form
      end
    end
  end
end
