class Api::MessagesController < Api::TenantController
  include AuditableApiEvents
  rescue_from ActiveRecord::RecordNotFound, with: :handle_exception

  # TODO: tu by som uz potreboval naozaj vediet, kto ma vola, aby som validoval tenanta. Idealne by mi asi ani posielat tenanta nemal

  def show
    @message = Message.includes(objects: :message_object_datum).find(params[:id])
    return if @message

    render :error, status: :unprocessable_entity
  end

  private

  def handle_exception(exception)
    @exception = exception
    render :error, status: :not_found
  end
end
