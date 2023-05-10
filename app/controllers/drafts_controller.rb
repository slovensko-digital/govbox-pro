class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :submit]

  def index
    @drafts = Current.subject.drafts
  end

  def show
  end

  def destroy
    Draft.find(params[:id]).destroy

    redirect_to drafts_path
  end

  def destroy_all
    Current.subject.drafts_imports.destroy_all
    Current.subject.drafts.destroy_all

    redirect_to drafts_path
  end

  def submit
    @draft.being_submitted!

    Drafts::SubmitJob.perform_later(@draft)
  end

  private

  def set_draft
    @draft = Current.subject.drafts.find(params[:id])
  end
end
