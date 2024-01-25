module Govbox
  class CheckMessagesMappingJob < ApplicationJob
    queue_as :default

    def perform
      unmapped_govbox_message_ids = []

      Govbox::Message.find_each do |govbox_message|
        mapped_message = ::Message.where(uuid: govbox_message.message_id)
                           .joins(:thread).where(thread: { box_id: govbox_message.box.id }).take
        unmapped_govbox_message_ids << govbox_message.id unless mapped_message
      end

      raise "Unmapped GovBox::Message IDs: #{unmapped_govbox_message_ids}" if unmapped_govbox_message_ids.any?
    end
  end
end
