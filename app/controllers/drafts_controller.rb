class DraftsController < ApplicationController
  before_action :load_draft, only: [:show, :submit]
  before_action :load_drafts, only: [:index, :destroy, :destroy_all, :submit_all]
  before_action :load_drafts_imports, only: [:destroy_all]

  def index
    @drafts = @drafts.order(created_at: :desc)
  end

  def show
  end

  def destroy
    @drafts.find(params[:id]).destroy

    redirect_to drafts_path
  end

  def destroy_all
    @drafts_imports.destroy_all
    @drafts.destroy_all

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
    @draft = Current.subject.drafts.find(params[:id] || params[:draft_id])
  end

  def load_drafts
    @drafts = Current.subject.drafts
  end

  def load_drafts_imports
    @drafts_imports = Current.subject.drafts_imports
  end
end
