class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
    @visible_tags = message_thread.tags.select { |tag| tag.visible }
  end
end
