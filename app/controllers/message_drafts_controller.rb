class MessageDraftsController < ApplicationController
  before_action :load_message_draft

  include ActionView::RecordIdentifier
  include MessagesConcern
  include MessageThreadsConcern

  def submit
    authorize @message

    render :update_body and return unless @message.valid?(:validate_data)

    if @message.submit
      redirect_to message_thread_path(@message.thread), notice: "Správa bola zaradená na odoslanie"
    else
      redirect_to message_thread_path(@message.thread), alert: @message.not_submittable_errors.join(', ')
    end
  end

  def update
    authorize @message

    @message.update_content(message_draft_params)

    flash[:notice] = 'Zmeny boli uložené'
  end

  def destroy
    authorize @message

    # TODO uncomment when /message_drafts endpoint has FE
    # redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_drafts_path
    redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_threads_path

    if @message.not_yet_submitted?
      @message.destroy
      redirect_to redirect_path, notice: "Správa bola zahodená"
    else
      redirect_to redirect_path, alert: "Správu nie je možné zmazať po odoslaní"
    end
  end

  def unlock
    authorize @message
    if @message.remove_form_signature
      redirect_to message_thread_path(@message.thread), notice: "Podpisy boli úspešne odstránené, správu je možné upravovať"
    else
      redirect_to message_thread_path(@message.thread), alert: "Nastala neočakávaná chyba, nepodarilo sa odstrániť podpisy"
    end
  end

  def confirm_unlock
    authorize @message
  end

  private

  def load_message_draft
    @message = policy_scope(MessageDraft).find(params[:id])
  end

  def message_draft_params
    attributes = MessageTemplateParser.parse_template_placeholders(@message.template).map{|item| item[:name]}
    params[:message_draft].permit(attributes)
  end
end
