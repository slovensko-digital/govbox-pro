class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def before_render
    # TODO: Fix security hole - no pundit
    @selected_message = Message.find(params[:id])
    @message_thread = @selected_message.thread
  end
end
