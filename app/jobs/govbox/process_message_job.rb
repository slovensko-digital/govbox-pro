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
        create_relations_with_related_messages(message)
      end
    end

    def destroy_associated_message_draft(govbox_message)
      message_draft = MessageDraft.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take

      if message_draft
        message_thread = message_draft.thread
        message_draft.destroy

        drafts_tag = message_thread.tags.find_by(name: "Drafts")
        message_thread.tags.delete(drafts_tag) unless message_thread.message_drafts.any?
      end
    end

    def mark_associated_delivery_notification_authorized(govbox_message)
      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id)
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.find_by(uuid: delivery_notification_govbox_message.message_id)
        delivery_notification_message.collapsed = true
        delivery_notification_message.metadata["authorized"] = true
        delivery_notification_message.save!
      end
    end

    def create_relations_with_related_messages(message)
      related_messages = ::Message.where("metadata ->> 'reference_id' = ?", message.uuid).joins(thread: { folder: :box })
                                .where(thread: { folders: { boxes: { id: message.thread.folder.box.id } } })

      related_messages.each do |related_message|
        govbox_related_message = Govbox::Message.where(message_id: related_message.uuid).joins(folder: :box).where(folders: { boxes: { id: related_message.thread.folder.box.id } }).take

        if govbox_related_message.related_message_type
          message.message_relations.find_or_create_by(
            related_message: related_message,
            relation_type: govbox_related_message.related_message_type
          )
        end
      end
    end
  end
end
