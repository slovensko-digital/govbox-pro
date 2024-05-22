class Fs::MessageDraftsController < ApplicationController
  before_action :load_selected_box, only: :create
  before_action :load_selected_fs_form, only: :create

  def new
    @message = MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end

  def create
    @message = ::Fs::MessageDraft.create_and_validate_with_fs_form(@fs_form, box: @box, form_file: message_draft_params[:content])

    authorize @message

    unless @message.valid?
      render :update_new and return
    end

    redirect_to message_thread_path(@message.thread)
  end

  private

  def load_selected_box
    @box = Fs::Box.find(message_draft_params[:sender_id])
  end


  def load_selected_fs_form
    @fs_form = Fs::Form.find(message_draft_params[:form_id])
  end

  def message_draft_params
    params.permit(
      :sender_id,
      :form_id,
      :content
    )
  end
end
