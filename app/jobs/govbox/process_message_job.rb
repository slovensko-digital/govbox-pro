require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    queue_as :default

    retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :exponentially_longer, attempts: Float::INFINITY

    def perform(govbox_message)
      ActiveRecord::Base.transaction do
        message = Govbox::Message.create_message_with_thread!(govbox_message)

        destroy_associated_message_draft(govbox_message)
        mark_delivery_notification_authorized(govbox_message)
        mark_associated_delivery_notification_authorized(govbox_message)
        collapse_referenced_outbox_message(message)
        create_message_relations(message)
      end
    end

    def destroy_associated_message_draft(govbox_message)
      message_draft = MessageDraft.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
      message_draft&.destroy
    end

    def mark_delivery_notification_authorized(govbox_message)
      return unless govbox_message.delivery_notification

      authorized_govbox_message = Govbox::Message.where(message_id: govbox_message.delivery_notification['consignment']['message_id'])
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if authorized_govbox_message
        delivery_notification_message = ::Message.where(uuid: govbox_message.message_id)
                                                 .joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
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
                                                 .joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
        mark_delivery_notificiation_message_authorized(delivery_notification_message) if delivery_notification_message
      end
    end

    def create_message_relations(message)
      related_messages = ::Message.where("metadata ->> 'reference_id' = ?", message.uuid).joins(thread: { folder: :box })
                                .where(thread: { folders: { boxes: { id: message.thread.folder.box.id } } })

      related_messages.each do |related_message|
        message.message_relations.find_or_create_by!(
          related_message: related_message
        )
      end

      main_message = ::Message.where(uuid: message.metadata['reference_id']).joins(thread: { folder: :box })
                                .where(thread: { folders: { boxes: { id: message.thread.folder.box.id } } }).take

      main_message.message_relations.find_or_create_by!(
        related_message: message
      ) if main_message
    end

    def collapse_referenced_outbox_message(message)
      return if message.collapsed?

      if message.outbox?
        # TODO change .where(collapsed: false) to .where(hidden: true)
        referring_messages = message.thread.messages.inbox.where("metadata ->> 'reference_id' = ?", message.uuid).where(collapsed: false)
        message.update(collapsed: true) if referring_messages
      else
        message.thread.messages.outbox.where(uuid: message.metadata["reference_id"]).take&.update(
          collapsed: true
        )
      end
    end

    private

    def mark_delivery_notificiation_message_authorized(delivery_notification_message)
      delivery_notification_message.collapsed = true
      delivery_notification_message.metadata['authorized'] = true
      delivery_notification_message.save!

      delivery_notification_tag = Tag.find_by!(
        system_name: Govbox::Message::DELIVERY_NOTIFICATION_TAG,
        tenant: delivery_notification_message.thread.box.tenant,
      )
      delivery_notification_message.tags.delete(delivery_notification_tag) if delivery_notification_message.tags.include?(delivery_notification_tag)
      unless delivery_notification_message.thread.messages.any?(&:can_be_authorized?)
        delivery_notification_message.thread.tags.delete(delivery_notification_tag)
      end
    end
  end
end
