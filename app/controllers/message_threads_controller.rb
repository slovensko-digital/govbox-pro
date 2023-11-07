class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show rename update search_available_tags show_history]
  before_action :set_thread_tags, only: %i[show show_history]
  before_action :set_thread_messages, only: %i[show show_history]
  before_action :load_threads, only: %i[index scroll]
  after_action :mark_thread_as_read, only: %i[show show_history]

  def show
    authorize @message_thread
  end

  def rename
    authorize @message_thread
  end

  def update
    authorize @message_thread

    path = message_thread_path(@message_thread)

    return unless @message_thread.update(message_thread_params)

    redirect_back fallback_location: path, notice: 'Názov vlákna bol upravený'
  end

  def index
    authorize MessageThread
  end

  def scroll
    authorize MessageThread
  end

  def bulk_actions
    authorize MessageThread

    @ids = params[:message_thread_ids] || []
  end

  def bulk_merge
    authorize MessageThread
    @ids = params[:message_thread_ids] || []

    message_thread = merge_threads(@ids)
    if message_thread
      redirect_to message_thread_path(message_thread), notice: 'Vlákna boli úspešne spojené'
    else
      flash[:alert] = 'Označte zaškrtávacími políčkami minimálne 2 vlákna, ktoré chcete spojiť'
      redirect_back fallback_location: message_threads_path
    end
  end

  def merge_threads(message_thread_ids)
    selected_message_threads = message_thread_policy_scope.where(id: message_thread_ids).order(:last_message_delivered_at)
    return nil if !selected_message_threads || selected_message_threads.size < 2

    selected_message_threads.merge_threads

    selected_message_threads.first
  end

  def load_threads
    cursor = MessageThreadCollection.init_cursor(search_params[:cursor])

    result =
      MessageThreadCollection.all(
        scope: message_thread_policy_scope.includes(:tags, :box),
        search_permissions: search_permissions,
        query: search_params[:q],
        cursor: cursor
      )

    @message_threads, @next_cursor = result.fetch_values(:records, :next_cursor)
    @next_cursor = MessageThreadCollection.serialize_cursor(@next_cursor)
    @next_page_params = search_params.to_h.merge(cursor: @next_cursor).merge(format: :turbo_stream)
  end

  def show_history
    authorize @message_thread
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:id])
  end

  def mark_thread_as_read
    @message_thread.mark_all_messages_read
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def search_permissions
    result = { tenant: Current.tenant }
    result[:box] = Current.box if Current.box
    result[:tag_ids] = policy_scope(Tag).pluck(:id)
    result
  end

  def message_thread_params
    params.require(:message_thread).permit(:title, :original_title, :merge_uuids, :tag_id, :tags)
  end

  def search_params
    params.permit(:q, :format, cursor: MessageThreadCollection::CURSOR_PARAMS)
  end

  def set_thread_tags
    @thread_tags = @message_thread.message_threads_tags.only_visible_tags
  end

  def set_thread_messages
    @thread_messages = @message_thread.messages_visible_to_user(Current.user).includes(objects: :nested_message_objects, attachments: :nested_message_objects).order(delivered_at: :asc)
  end
end
