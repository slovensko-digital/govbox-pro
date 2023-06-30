class Layout::MessageThreadSidebarComponent < ViewComponent::Base
  def before_render
    # TODO: Fix security hole - no pundit
    @message_thread = Message.find(params[:id]).thread
  end
end
