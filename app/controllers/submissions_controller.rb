class SubmissionsController < ApplicationController
  def index
    @submissions = subject.submissions
  end

  def show
    @submission = Submission.find(params[:id])
  end

  def destroy
    Submission.find(params[:id]).destroy

    redirect_to :action => 'index'
  end

  def submit(submit_job: Submissions::SubmitJob)
    @submission = Submission.find(params[:submission_id])
    mark_submission_as_being_submitted(@submission)
    submit_job.new.perform(@submission)
    # submit_job.perform_later(@submission_package)
  end

  private

  def mark_submission_as_being_submitted(submission)
    Submission.transaction do
      submission.update(status: 'being_submitted')
    end
  end
end
