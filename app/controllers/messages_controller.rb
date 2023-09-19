class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @message.update(read: true)
    @message_thread = @message.thread
    @available_tags = available_tags

    @notice = notice
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
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end

  def available_tags
    @tenant = @message.tenant
    @tenant.tags.where.not(id: @message.tags.ids).where(visible: true)
           .where(
             id: TagGroup.select(:tag_id)
              .joins(:group, :tag, group: :users)
              .where(group: { tenant_id: @tenant.id }, tag: { tenant_id: @tenant.id }, users: { id: Current.user.id })
           )
  end
end
