class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show]

  def show
    authorize @message_thread
  end

  def index
    authorize MessageThread
    @cursor = params[:cursor] || {}
    @cursor[:delivered_at] = @cursor[:delivered_at] ? millis_to_time(@cursor[:delivered_at]) : Time.now

    @message_threads_collection = policy_scope(MessageThread)
    if params[:tag_id]
      # TODO: Janovi sa nepacilo, prejst
      @message_threads_collection = @message_threads_collection.where(
            'message_threads.id in (select mt.id from message_threads mt
                  join message_threads_tags mtags on mt.id = mtags.message_thread_id
                  where mtags.tag_id = ?)',
            params[:tag_id]
          )
    end
 
    
    @message_threads, @next_cursor =
      Pagination.paginate(
        collection:
          # TODO - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
          @message_threads_collection
          .select(
            'message_threads.*,
          (select count(messages.id) from messages where messages.message_thread_id = message_threads.id) as messages_count,
          coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
          (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom'
          ),
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

  private

  MESSAGE_THREADS_PER_PAGE = 10

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
