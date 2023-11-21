class Box
  module MessageThreadsExtensions
    def find_or_create_by_merge_uuid!(box:, merge_uuid:, title:, delivered_at:)
      thread = MessageThread.joins(:merge_identifiers)
                            .where("message_thread_merge_identifiers.uuid = ?", merge_uuid)
                            .where(box: box).take
      
      if thread
        if thread.delivered_at > delivered_at
          # out-of-order processing
          thread.title = title
          thread.original_title = title
          thread.delivered_at = delivered_at
        else
          thread.last_message_delivered_at = delivered_at
        end
      else
        thread = build(
          box: box,
          title: title,
          original_title: title,
          delivered_at: delivered_at,
          last_message_delivered_at: delivered_at
        )
        thread.merge_identifiers.build(uuid: merge_uuid, box: box)
      end

      thread.save!

      thread
    end
  end
end
