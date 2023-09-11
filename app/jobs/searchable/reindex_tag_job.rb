class Searchable::ReindexTagJob < ApplicationJob
  queue_as :default

  def perform(tag_id)
    ::Searchable::MessageThread.select(:id, :message_thread_id).
      where("tag_ids && ARRAY[?]", [tag_id]).
      find_each do |searchabe_message_thread|

      thread = ::MessageThread.find(searchabe_message_thread.message_thread_id)
      Searchable::ReindexMessageThreadJob.perform_later(thread)
    end

  end
end
