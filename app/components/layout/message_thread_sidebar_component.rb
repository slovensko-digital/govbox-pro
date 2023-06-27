class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def before_render
    # TODO: Fix security hole - no pundit
    @message = Message.find(params[:id])
    @message_thread = @message.thread
  end
end
