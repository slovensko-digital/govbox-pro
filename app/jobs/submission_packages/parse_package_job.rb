require 'csv'

class SubmissionPackages::ParsePackageJob < ApplicationJob
  queue_as :high_priority

  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(package, package_zip_path, load_package_info_job: SubmissionPackages::LoadPackageInfoJob, load_package_data_job: SubmissionPackages::LoadPackageDataJob)
    extracted_package_path = File.join(Utils.file_directory(package_zip_path), File.basename(package_zip_path, ".*"))
    system("unzip", package_zip_path, '-d', extracted_package_path)

    # TODO change jobs from perform to perform_later
    Dir.each_child(extracted_package_path) do |entry_name|
      if entry_name.end_with?('.csv')
        load_package_info_job.new.perform(package, File.join(extracted_package_path, entry_name))
      elsif Utils.directory?(entry_name)
        submission = Submission.find_or_create_by!(
          package_id: package.id,
          package_subfolder: File.basename(entry_name)
        )
        load_package_data_job.new.perform(submission, File.join(extracted_package_path, entry_name))
      end
    end
  end
end
