class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
    @visible_tags = message_thread.tags.select { |tag| tag.visible }
  end

  def last_section?
    @message_thread.with_whom || @message_thread.last_message_delivered_at
  end
end
