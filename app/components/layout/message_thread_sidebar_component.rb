class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def initialize(message:)
    @selected_message = message
    @thread_messages = @selected_message.thread.messages_visible_to_user(Current.user).order(delivered_at: :asc)
  end
end
