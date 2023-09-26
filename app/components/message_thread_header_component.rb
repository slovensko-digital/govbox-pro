class MessageThreadHeaderComponent < ViewComponent::Base
  def initialize(message_thread, available_tags)
    @message_thread = message_thread
    @available_tags = available_tags
  end
end
