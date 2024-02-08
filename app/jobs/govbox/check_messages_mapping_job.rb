module Govbox
  class CheckMessagesMappingJob < ApplicationJob
    queue_as :default

    def perform
      unmapped_govbox_messages = Govbox::Message.find_by_sql(
        ["SELECT gm.id FROM govbox_messages gm JOIN govbox_folders gf ON gm.folder_id = gf.id
          WHERE gm.delivered_at > ?
          AND NOT EXISTS (
          SELECT 1 FROM messages m
          JOIN message_threads mt ON m.message_thread_id = mt.id
          WHERE m.uuid = gm.message_id
          AND mt.box_id = gf.box_id
          LIMIT 1
         )", 1.months.ago]
      )

      raise "Unmapped GovBox::Message IDs: #{unmapped_govbox_messages.pluck("id")}" if unmapped_govbox_messages.any?
    end
  end
end
