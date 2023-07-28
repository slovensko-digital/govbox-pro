class MirgateMergeUuidsToMessageThreadMergeIdentifiers < ActiveRecord::Migration[7.0]
  def up
    MessageThread.order(:delivered_at).find_each do |message_thread|
      message_thread.merge_uuids.each do |merge_uuid|
        other_existing_thread = MessageThreadMergeIdentifier.find_by(
          uuid: merge_uuid
        )&.message_thread

        if other_existing_thread
          # merge threads
          if message_thread != other_existing_thread
            message_thread.merge_uuids.each do |merge_uuid|
              MessageThreadMergeIdentifier.find_or_create_by(
                uuid: merge_uuid,
                message_thread: other_existing_thread
              )
            end

            message_thread.messages.each do |message|
              message.update(
                thread: other_existing_thread
              )
            end
            
            message_thread.tags.each do |tag|
              other_existing_thread.tags.push(tag) if !other_existing_thread.tags.include?(tag)
            end
            
            message_thread.destroy!
          end
        else
          MessageThreadMergeIdentifier.create(
            uuid: merge_uuid,
            message_thread: message_thread
          )
        end
      end
    end
  end
end
