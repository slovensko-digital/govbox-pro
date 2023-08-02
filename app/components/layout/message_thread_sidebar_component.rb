class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def initialize(message:)
    @selected_message = message
    @thread_messages = @selected_message.thread.messages.order(delivered_at: :desc)
  end
end
