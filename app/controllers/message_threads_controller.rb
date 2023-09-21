class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show update archive move_to_inbox]

  def show
    authorize @message_thread

    redirect_to @message_thread.messages.where(read: false).order(delivered_at: :asc).first || @message_thread.messages_visible_to_user(Current.user).order(delivered_at: :desc).first
  end

  def update
    authorize @message_thread
    if @message_thread.update(message_thread_params)
      redirect_back fallback_location: messages_path(@message_thread.messages.first)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def index
    authorize MessageThread

    cursor = MessageThreadCollection.init_cursor(search_params[:cursor])

    @message_threads, @next_cursor = MessageThreadCollection.all(
      scope: message_thread_policy_scope.includes(:tags),
      search_permissions: search_permissions,
      inbox_part: search_params[:type] || 'inbox',
      query: search_params[:q],
      no_visible_tags: search_params[:no_visible_tags] == '1' && Current.user.admin?,
      cursor: cursor
    )

    @next_cursor = MessageThreadCollection.serialize_cursor(@next_cursor)
    @next_page_params = search_params.to_h.merge(cursor: @next_cursor).merge(format: :turbo_stream)

    respond_to do |format|
      format.html # GET
      format.turbo_stream # POST
    end
  end

  def merge
    authorize MessageThread
    @selected_message_threads = message_thread_policy_scope.where(id: params[:message_thread_ids]).order(:last_message_delivered_at)
    if !@selected_message_threads || @selected_message_threads.size < 2
      flash[:error] = 'Označte zaškrtávacími políčkami minimálne 2 vlákna, ktoré chcete spojiť'
      redirect_back fallback_location: message_threads_path
      return
    end
    @selected_message_threads.merge_threads
    flash[:notice] = 'Vlákna boli úspešne spojené'
    redirect_to @selected_message_threads.first
  end

  def archive
    authorize MessageThread
    @message_thread.archive

    flash[:notice] = 'Vlákno bolo úspešne archivované'

    redirect_to message_thread_path(@message_thread)
  end

  def move_to_inbox
    authorize MessageThread
    @message_thread.move_to_inbox

    flash[:notice] = 'Vlákno bolo presunuté do doručených správ'

    redirect_to message_thread_path(@message_thread)
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:id])
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def search_permissions
    result = { tenant_id: Current.tenant }
    result[:tag_ids] = policy_scope(Tag).pluck(:id) unless Current.user.admin?
    result
  end

  def message_thread_params
    params.require(:message_thread).permit(:title, :original_title, :merge_uuids, :tag_id, :tags)
  end

  def search_params
    params.permit(:q, :no_visible_tags, :type, :format, cursor: MessageThreadCollection::CURSOR_PARAMS)
  end
end
