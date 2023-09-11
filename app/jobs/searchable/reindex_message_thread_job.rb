class Searchable::ReindexMessageThreadJob < ApplicationJob
  queue_as :default

  def perform(message_thread)
    puts "✅ reinding! #{message_thread.id}"

    ::Searchable::MessageThread.index_record(message_thread)
  end
end
