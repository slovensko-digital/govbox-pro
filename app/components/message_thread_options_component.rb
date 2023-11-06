class MessageThreadOptionsComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
  end
end
