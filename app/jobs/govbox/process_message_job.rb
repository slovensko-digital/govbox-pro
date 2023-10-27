require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    queue_as :default

    retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :exponentially_longer, attempts: Float::INFINITY

    def perform(govbox_message)
      ActiveRecord::Base.transaction do
        message = Govbox::Message.create_message_with_thread!(govbox_message)

        destroy_associated_message_draft(govbox_message)
        mark_associated_delivery_notification_authorized(govbox_message)
        collapse_previous_outbox_messages(message)
        create_message_relations(message)
      end
    end

    def destroy_associated_message_draft(govbox_message)
      message_draft = MessageDraft.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
      message_draft&.destroy
    end

    def mark_associated_delivery_notification_authorized(govbox_message)
      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id)
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.where(uuid: delivery_notification_govbox_message.message_id)
                                                 .joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
        delivery_notification_message.collapsed = true
        delivery_notification_message.metadata["authorized"] = true
        delivery_notification_message.save!
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

    def collapse_previous_outbox_messages(message)
      return if message.collapsed?

      message.previous_thread_outbox_messages.update_all(
        collapsed: true
      )
    end
  end
end
