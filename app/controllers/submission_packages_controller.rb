class SubmissionPackagesController < ApplicationController
  def create
    archive = Archive.new

    zip_content = params[:content]
    package = Submissions::Package.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}",
      subject_id: Current.subject.id  # TODO add tenant option (no subject selected)
    )

    package_path = archive.store("submissions", package_path(package), zip_content.read.force_encoding("UTF-8"))
    Drafts::ParseImportJob.perform_later(package, package_path)

    redirect_to submissions_path
  end

  private

  def package_path(package)
    File.join(String(Current.subject.id), package.name)
  end
end
