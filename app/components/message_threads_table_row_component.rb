class MessageThreadsTableRowComponent < ViewComponent::Base
  with_collection_parameter :message_thread

  def initialize(message_thread:, message_thread_iteration:)
    @message_thread = message_thread
    @visible_tags = message_thread.tags.select(&:visible).sort_by(&:name)
  end
end
