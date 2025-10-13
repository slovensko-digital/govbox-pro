class MessageThreadsTableRowComponent < ViewComponent::Base
  with_collection_parameter :message_thread

  def initialize(message_thread:, message_thread_iteration:)
    @message_thread = message_thread
    @message_thread_iteration = message_thread_iteration
  end

  def visible_tags
    helpers.sort_tags(@message_thread.tags.select(&:visible))
  end
end
