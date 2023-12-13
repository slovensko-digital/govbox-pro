class Api::MessageThreadsController < Api::TenantController
  include AuditableApiEvents
  rescue_from ActiveRecord::RecordNotFound, with: :handle_exception

  # TODO: tu by som uz potreboval naozaj vediet, kto ma vola, aby som validoval tenanta. Idealne by mi asi ani posielat tenanta nemal

  def show
    @thread = MessageThread.find(params[:id])
    @tags = @thread.tags
    @messages = Message.where(message_thread_id: params[:id]).select(:id)
    return if @thread && @tags && @messages

    render :error, status: :unprocessable_entity
  end

  private

  def handle_exception(exception)
    @exception = exception
    render :error, status: :not_found
  end
end
