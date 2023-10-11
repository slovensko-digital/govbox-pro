require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    queue_as :default

    retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :exponentially_longer, attempts: Float::INFINITY

    def perform(govbox_message)
      ActiveRecord::Base.transaction do
        Govbox::Message.create_message_with_thread!(govbox_message)
      end

      handle_message_draft_destroy

      # Mark message as authorized if there is a delivery notification
      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id)
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.find_by(uuid: delivery_notification_govbox_message.message_id)
        delivery_notification_message.metadata["authorized"] = true
        delivery_notification_message.save!
      end
    end

    def handle_message_draft_destroy
      message_draft = MessageDraft.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take

      if message_draft
        message_thread = message_draft.thread
        message_draft.destroy

        message_thread.tag.find_by(name: "Drafts").destroy unless message_thread.message_drafts.any?
      end
    end
  end
end

