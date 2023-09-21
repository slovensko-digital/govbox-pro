class MessageThreadHeaderComponent < ViewComponent::Base
  def initialize(message_thread, inbox_tag)
    @message_thread = message_thread
    @inbox_tag = inbox_tag
  end
end
