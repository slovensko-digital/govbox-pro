class SubmissionPackagesController < ApplicationController
  def index
    @submission_packages = subject.submission_packages
  end

  def create(parse_job: SubmissionPackages::ParsePackageJob, archive: Archive.new)
    zip_content = params[:content]
    package = Submissions::Package.create!(
      name: zip_content.original_filename,
      subject_id: 1 #TODO
    )

    package_path = archive.store('submissions', File.join(String(package.subject_id), zip_content.original_filename), zip_content.read.force_encoding("UTF-8"))
    parse_job.new.perform(package, package_path)
    # parse_job.perform_later(package, content)

    redirect_to :action => 'index'
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
