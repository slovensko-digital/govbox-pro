class DraftsController < ApplicationController
  def index
    @drafts = Current.subject.drafts
  end

  def show
    @draft = Draft.find(params[:id])
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
    @draft = Draft.find(params[:draft_id])
    mark_draft_as_being_submitted(@draft)

    Drafts::SubmitJob.perform_later(@draft)
  end

  private

  def mark_draft_as_being_submitted(draft)
    Draft.transaction do
      draft.update(status: 'being_submitted')
    end
  end
end
