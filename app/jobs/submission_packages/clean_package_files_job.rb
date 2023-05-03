class SubmissionPackages::CleanPackageFilesJob < ApplicationJob
  def perform(batch, params)
    Utils.delete_file(batch.properties[:zip_path])
    Utils.delete_file(batch.properties[:extracted_data_path])
  end
end
