class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show, update]

  def show
    authorize @message_thread
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
    @cursor = params[:cursor] || {}
    @cursor[DELIVERED_AT] = @cursor[DELIVERED_AT] ? millis_to_time(@cursor[DELIVERED_AT]) : Time.now

    @message_threads, @next_cursor =
      Pagination.paginate(
        collection: message_threads_collection,
        cursor: {
          DELIVERED_AT => @cursor[DELIVERED_AT],
          ID => @cursor[ID]
        },
        items_per_page: MESSAGE_THREADS_PER_PAGE,
        direction: 'desc'
      )

    @next_cursor[DELIVERED_AT] = time_to_millis(@next_cursor[DELIVERED_AT]) if @next_cursor
    @next_page_params = message_thread_params.merge(cursor: @next_cursor).merge(format: :turbo_stream)

    respond_to do |format|
      format.html # GET
      format.turbo_stream # POST
    end
  end

  # TODO: presunut logiku do modelu
  def merge
    authorize MessageThread
    @selected_message_threads = policy_scope(MessageThread).where(ID: params[:message_thread_ids]).order(:delivered_at)
    if !@selected_message_threads || @selected_message_threads.size < 2
      flash[:error] = 'Označte zaškrtávacími políčkami minimálne 2 vlákna, ktoré chcete spojiť'
      redirect_back fallback_location: message_threads_path
      return
    end
    @target_thread = @selected_message_threads.first
    MessageThread.transaction do
      @selected_message_threads.each_with_index do |thread, i|
        if i.positive?
          @target_thread.merge_uuIDs.union(thread.merge_uuIDs)
          thread.messages.each do |message|
            message.thread = @target_thread
            message.save!
          end
          thread.tags.each { |tag| @target_thread.tags.push(tag) if !@target_thread.tags.include?(tag) }
          thread.destroy!
        end
      end
      flash[:notice] = 'Vlákna boli úspešne spojené'
    end
    redirect_to @selected_message_threads.first.messages.first
  end

  private

  MESSAGE_THREADS_PER_PAGE = 20
  DELIVERED_AT = 'message_threads.delivered_at'
  ID = 'message_threads.id'

  def message_threads_collection
    @message_threads_collection = policy_scope(MessageThread).joins(:tags).includes(:tags)
    @message_threads_collection = @message_threads_collection.where(tags: { id: params[:tag_id] }) if params[:tag_id]
    if params[:tags] && params[:tags] == 'none' && Current.user.admin?
      @message_threads_collection =
        @message_threads_collection.where.not(message_threads: { id: (MessageThread.joins(:tags).where('tags.name not like ?', 'slovensko.sk:%')) })
    end
    add_calculated_fields
  end

  def add_calculated_fields
    @message_threads_collection.select(
      'message_threads.*',
      'tags.*',
      # TODO: - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
      '(select count(messages.id) from messages where messages.message_thread_id = message_threads.id) as messages_count,
      coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
        (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom',
      # last_message_id - potrebujeme kvoli spravnej linke na konkretny message, ktory chceme otvorit, a nech to netahame potom pre kazdy thread
      '(select max(messages.id) from messages where messages.message_thread_id = message_threads.id and messages.delivered_at = message_threads.delivered_at) as last_message_id'
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

  def message_thread_params
    params.permit(:message_thread, :title, :original_title, :merge_uuIDs, :tag_id, :tags, :format, cursor: [DELIVERED_AT, ID])
  end
end
