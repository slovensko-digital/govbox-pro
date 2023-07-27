class Box
  module MessageThreadsExtensions
    def find_or_create_by_merge_uuid!(folder:, merge_uuid:, title:, delivered_at:)
      thread = where('? = ANY(merge_uuids)', merge_uuid).first # TODO make sure this is fast

      if thread
        if thread.delivered_at > delivered_at
          # out-of-order processing
          thread.title = title
          thread.original_title = title
          thread.folder = folder
          thread.delivered_at = delivered_at
        else
          thread.last_message_delivered_at = delivered_at
        end
      else
        thread = build(
          merge_uuids: [merge_uuid],
          folder: folder,
          title: title,
          original_title: title,
          delivered_at: delivered_at,
          last_message_delivered_at: delivered_at
        )
      end

      thread.save!

      thread
    end
  end
end