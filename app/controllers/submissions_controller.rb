class SubmissionsController < ApplicationController
  def index
    @submission_packages = subject.submission_packages
  end

  def create(parse_job: Submissions::ParsePackageJob)
    package_content = params[:content]
    package = Submissions::Package.create!(
      name: package_content.original_filename,
      content: package_content.read,
      subject_id: 1 #TODO
    )

    parse_job.new.perform(package)
    # parse_job.perform_later(package)

    redirect_to :action=>'index'
  end

  def show
    @submission_package = Submissions::Package.find(params[:id])
  end

  def submit
    @submission_package = Submissions::Package.find(params[:submission_id])
    mark_submissions_as_being_submitted(@submission_package.submissions)
    Submissions::SubmitPackageJob.new.perform(@submission_package)
    # Submissions::SubmitPackageJob.perform_later(@submission_package)
  end

  private

  def mark_submissions_as_being_submitted(submissions)
    Submission.transaction do
      submissions.each do |s|
        s.update(status: 'being_submitted')
      end
    end
  end
end
