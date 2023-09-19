class Searchable::ReindexMessageThreadJob < ApplicationJob
  queue_as :default

  def perform(message_thread)
    ::Searchable::MessageThread.index_record(message_thread)
  end
end
