class SubmissionPackagesController < ApplicationController
  def create(parse_job: SubmissionPackages::ParsePackageJob, archive: Archive.new)
    zip_content = params[:content]
    package = Submissions::Package.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}",
      subject_id: current_subject.id
    )

    package_path = archive.store("submissions", package_path(package), zip_content.read.force_encoding("UTF-8"))
    parse_job.perform_later(package, package_path)

    redirect_to :action => "index", :controller => "submissions"
  end

  def submit(submit_job: SubmissionPackages::SubmitPackageJob)
    @submission_package = Submissions::Package.find(params[:submission_package_id])
    mark_submissions_as_being_submitted(@submission_package.submissions)
    submit_job.perform_later(@submission_package)
  end

  private

  def package_path(package)
    File.join(String(current_subject.id), package.name)
  end

  def mark_submissions_as_being_submitted(submissions)
    Submission.transaction do
      submissions.each do |s|
        s.update(status: "being_submitted")
      end
    end
  end
end
