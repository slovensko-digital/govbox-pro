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

  private

  def package_path(package)
    File.join(String(current_subject.id), package.name)
  end
end
