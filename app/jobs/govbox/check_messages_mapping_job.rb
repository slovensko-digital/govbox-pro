module Govbox
  class CheckMessagesMappingJob < ApplicationJob
    def perform
      unmapped_govbox_message_ids = ::Govbox::Message.joins(:folder).where.not(
        ::Message.select(1).joins(:thread)
                 .where('messages.uuid = govbox_messages.message_id')
                 .where('message_threads.box_id = govbox_folders.box_id')
                 .arel.exists
      ).pluck(:id)

      raise "Unmapped GovBox::Message IDs: #{unmapped_govbox_message_ids}" if unmapped_govbox_message_ids.any?
    end
  end
end
