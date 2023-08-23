class MessageDraftsController < ApplicationController
  before_action :load_message_drafts, only: :index
  before_action :set_message, only: :create
  before_action :load_draft, except: [:index, :create]

  def index
    @message_drafts = @message_drafts.order(created_at: :desc)
  end

  def create
    authorize @message

    @message_draft = MessageDraft.create_message_reply(@message)

    redirect_to message_draft_path(@message_draft)
  end

  def show
    authorize @message_draft
    @notice = notice
  end

  def update
    authorize @message_draft

    permitted_params = message_params

    @message_draft.update_content(title: permitted_params["message_title"], body: permitted_params["message_text"])
  end

  def submit
    authorize @message_draft

    if @message_draft.submittable?
      @message_draft.submit
      redirect_to message_path(@message_draft.original_message), notice: "Správa bola zaradená na odoslanie."
    else
      # TODO prisposobit importovanym draftom
      redirect_to message_draft_path(@message_draft), notice: "Vyplňte predmet a text odpovede."
    end
  end
  
  def submit_all
    @message_drafts.each do |message_draft|
      message_draft.submit if message_draft.submittable?
    end
  end

  def destroy
    authorize @message_draft

    @message_draft.destroy
    redirect_to (params[:redirect_url] || message_drafts_path)
  end

  private

  def load_message_drafts
    authorize MessageDraft
    @message_drafts = policy_scope(MessageDraft)
  end

  def set_message
    @message = policy_scope(Message).find(params[:original_message_id])
  end

  def load_draft
    @message_draft = policy_scope(MessageDraft).find(params[:id])
    @menu = SidebarMenu.new(controller_name, action_name, { message: @message_draft })
  end

  def message_params
    params.permit(:message_title, :message_text)
  end
end
