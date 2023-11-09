class MessageThreadOptionsComponent < ViewComponent::Base

  def initialize(message_thread, classes="")
    @message_thread = message_thread
    @classes = classes
  end
end
