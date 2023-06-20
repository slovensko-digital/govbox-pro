class MessageThreadsController < ApplicationController
  include Pagination
  # TODO - vyhodit, len pre debug
  include Automate

  before_action :set_message_thread, only: %i[show]

  MESSAGE_THREADS_PER_PAGE = 10

  def show
    authorize @message_thread
  end

  def index
    authorize MessageThread
    @cursor = params[:cursor] || {delivered_at: time_to_millis(Time.now)}
    @cursor[:delivered_at] = millis_to_time(@cursor[:delivered_at]) || Time.now

    @message_threads, @next_cursor = paginate(collection: policy_scope(MessageThread)
        .where("message_threads.id in (select mt.id from message_threads mt
                  join messages m on m.message_thread_id = mt.id
                  join messages_tags mtags on m.id = mtags.message_id
                  where mtags.tag_id = ?)", params[:tag_id])
        # TODO - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
        .select("message_threads.*,
          (select count(messages.id) from messages where messages.message_thread_id = message_threads.id) as messages_count,
          coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
          (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom"),
        params: {
          items_per_page: MESSAGE_THREADS_PER_PAGE,
          direction: "desc"
        },
        cursor: [
          {
            name: "delivered_at",
            value: @cursor[:delivered_at]
          },
          {
            name: "id",
            value: @cursor[:id] ? @cursor[:id]: nil
          }
        ]
        )

    @next_cursor[:delivered_at] = time_to_millis(@next_cursor[:delivered_at]) unless @next_cursor.empty?

    
    respond_to do |format|
      format.html # GET
      format.turbo_stream # POST
    end
  end

  # TODO - vyhodit, len pre debug
  def run_rules
    @message_thread = policy_scope(MessageThread).find(params[:id])
    run_rules_for(@message_thread, :message_created)
  end

  private

  def time_to_millis(time)
    time.strftime("%s%L").to_f
  end

  def millis_to_time(millis)
    Time.at(millis.to_f/1000)
  end

  def set_message_thread
    @message_thread = policy_scope(MessageThread).find(params[:id])
  end

  def page_params
    params.permit(:cursor)
  end
end
