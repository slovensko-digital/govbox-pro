class MessagesController < ApplicationController
  before_action :set_message

  include MessagesConcern

  def show
    authorize @message

    @message.update(read: true)
    @message_thread = @message.thread
    @thread_messages = @message_thread.messages_visible_to_user(Current.user).order(delivered_at: :asc)
  end

  def authorize_delivery_notification
    authorize @message

    notice = Message.authorize_delivery_notification(@message) ? "Správa bola zaradená na prevzatie." : "Správu nie je možné prevziať."
    redirect_to message_path(@message), notice: notice
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
    @menu = SidebarMenu.new(controller_name, action_name, { message: @message })
    @notice = flash
    set_thread_tags_with_deletable_flag
  end
end
