class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def initialize(message:)
    @selected_message = message
    @message_thread = @selected_message.thread
  end
end
