require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    queue_as :default

    def perform(govbox_message)
      ActiveRecord::Base.transaction do
        Govbox::Message.create_message_with_thread!(govbox_message)
      end

      # Remove message draft if exists
      message_draft = MessageDraft.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
      message_draft.destroy if message_draft
    end
  end
end

