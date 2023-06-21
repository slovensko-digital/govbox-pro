class DraftsController < ApplicationController
  before_action :load_draft, only: [:show, :submit]
  before_action :load_drafts, only: [:index, :destroy, :submit_all]

  def index
    @drafts = @drafts.order(created_at: :desc)
  end

  def show
  end

  def destroy
    @drafts.find(params[:id]).destroy

    redirect_to drafts_path
  end

  def submit
    submit_draft(@draft)
  end

  def submit_all
    @drafts.each do |draft|
      submit_draft(draft) if draft.submittable?
    end
  end

  private

  def submit_draft(draft)
    draft.being_submitted!
    Drafts::SubmitJob.perform_later(draft)
  end

  def load_draft
    @draft = policy_scope(Draft).find(params[:id] || params[:draft_id])
    authorize @draft
  end

  def load_drafts
    authorize Draft
    @drafts = policy_scope(Draft)
  end
end
