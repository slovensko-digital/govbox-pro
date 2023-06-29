class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show]

  def show
    authorize @message_thread
  end

  def index
    authorize MessageThread
    @cursor = params[:cursor] || {}
    @cursor[:delivered_at] = @cursor[:delivered_at] ? millis_to_time(@cursor[:delivered_at]) : Time.now

    @message_threads, @next_cursor =
      Pagination.paginate(
        collection: message_threads_collection,
        cursor: {
          delivered_at: @cursor[:delivered_at],
          id: @cursor[:id]
        },
        items_per_page: MESSAGE_THREADS_PER_PAGE,
        direction: 'desc'
      )

    @next_cursor[:delivered_at] = time_to_millis(@next_cursor[:delivered_at]) if @next_cursor

    respond_to do |format|
      format.html # GET
      format.turbo_stream # POST
    end
  end

  def merge
    authorize MessageThread
    @selected_message_threads = policy_scope(MessageThread).where(id: params[:message_thread_ids]).order(:delivered_at)
    if !@selected_message_threads || @selected_message_threads.size < 2
      flash[:error] = 'Označte zaškrtávacími políčkami minimálne 2 vlákna, ktoré chcete spojiť'
      redirect_back fallback_location: message_threads_path
      return
    end
    @target_thread = @selected_message_threads.first
    MessageThread.transaction do
      @selected_message_threads.each_with_index do |thread, i|
        if i.positive?
          @target_thread.merge_uuids.union(thread.merge_uuids)
          thread.messages.each do |message|
            message.thread = @target_thread
            message.save!
          end
          thread.tags.each do |tag|
            @target_thread.tags.push(tag) if !@target_thread.tags.include?(tag)
          end 
          thread.destroy!
        end
      end
      flash[:notice] = 'Vlákna boli úspešne spojené'
    end
    redirect_to @selected_message_threads.first.messages.first
  end

  private

  MESSAGE_THREADS_PER_PAGE = 10

  def message_threads_collection
    @message_threads_collection = policy_scope(MessageThread)
    if params[:tag_id]
      @message_threads_collection =
        @message_threads_collection.where(
          'message_threads.id in (select mt.id from message_threads mt
                  join message_threads_tags mtags on mt.id = mtags.message_thread_id
                  where mtags.tag_id = ?)',
          params[:tag_id]
        )
    end
    # TODO - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
    @message_threads_collection.select(
      'message_threads.*,
              (select count(messages.id) from messages where messages.message_thread_id = message_threads.id) as messages_count,
              coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
              (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom'
    )
  end
  def time_to_millis(time)
    time.strftime('%s%L').to_f
  end

  def millis_to_time(millis)
    Time.at(millis.to_f / 1000)
  end

  def set_message_thread
    @message_thread = policy_scope(MessageThread).find(params[:id])
  end

  def page_params
    params.permit(:cursor)
  end
end
