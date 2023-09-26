class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @message.update(read: true)
    @message_thread = @message.thread
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
    set_message_tags_with_deletable_flag
    set_thread_tags_with_deletable_flag
  end

  def set_message_tags_with_deletable_flag
    @message_tags_with_deletable_flag =
      @message
        .messages_tags
        .includes(:tag)
        .select("messages_tags.*, #{deletable_subquery('tags.id = messages_tags.tag_id').to_sql} as deletable")
        .order("tags.name")
  end

  def set_thread_tags_with_deletable_flag
    @thread_tags_with_deletable_flag =
      @message
        .thread
        .message_threads_tags
        .includes(:tag)
        .select("message_threads_tags.*, #{deletable_subquery('tags.id = message_threads_tags.tag_id').to_sql} as deletable")
        .order('tags.name')
  end

  def deletable_subquery(where_clause)
    Tag
      .joins(:groups, { groups: :group_memberships })
      .where('group_memberships.user_id = ?', Current.user.id)
      .where(where_clause)
      .arel
      .exists
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
