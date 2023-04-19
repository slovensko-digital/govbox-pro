class SubmissionPackages::CleanPackageFilesJob < ApplicationJob
  queue_as :low_priority

  def perform(batch, params)
    Utils.delete_file(batch.properties[:zip_path])
    Utils.delete_file(batch.properties[:extracted_data_path])
  end
end
