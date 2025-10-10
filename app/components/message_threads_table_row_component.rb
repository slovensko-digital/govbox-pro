class MessageThreadsTableRowComponent < ViewComponent::Base
  with_collection_parameter :message_thread

  def initialize(message_thread:, message_thread_iteration:)
    @message_thread = message_thread
    @message_thread_iteration = message_thread_iteration
    @visible_tags = message_thread.tags.select(&:visible).sort_by(&:name).sort_by{|i| i.type.in?(%W[ValidationWarningTag ValidationErrorTag]) ? 1 : 0 }
  end
end
