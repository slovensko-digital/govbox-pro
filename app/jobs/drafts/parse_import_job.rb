require 'csv'

class Drafts::ParseImportJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(package, package_zip_path, jobs_batch: GoodJob::Batch.new, load_submission_content_job: Drafts::LoadContentJob, on_success_job: Drafts::FinishImportJob)
    extracted_package_path = File.join(Utils.file_directory(package_zip_path), File.basename(package_zip_path, ".*"))
    system("unzip", package_zip_path, '-d', extracted_package_path)

    package.update(content_path: extracted_package_path)

    raise "Invalid package" unless package.valid?

    csv_paths = Dir[extracted_package_path + "/*.csv"]

    submissions_from_csv = load_package_csv(package, csv_paths.first)
    submissions_from_folders = []

    Dir.each_child(extracted_package_path) do |entry_name|
      if File.directory?(File.join(extracted_package_path, entry_name))
        submission = Submission.find_or_create_by!(
          subject_id: package.subject.id,
          package_id: package.id,
          package_subfolder: File.basename(entry_name)
        )
        submission.update(status: "being_loaded")
        submissions_from_folders << submission

        jobs_batch.add do
          load_submission_content_job.perform_later(submission, File.join(extracted_package_path, entry_name))
        end
      end
    end

    all_submissions = (submissions_from_csv + submissions_from_folders).uniq
    jobs_batch.enqueue(on_success: on_success_job, package: package, drafts: all_submissions, zip_path: package_zip_path, extracted_data_path: extracted_package_path)

    package.update(status: "parsed")
  rescue
    # TODO Send notification
    package.destroy!
  end

  private

  def load_package_csv(package, csv_path)
    submissions = []

    csv_options = {
      encoding: 'UTF-8',
      col_sep: File.open(csv_path) { |f| f.readline }.include?(';') ? ';' : ',',
      headers: true
    }

    CSV.parse(File.read(csv_path), **csv_options) do |row|
      submissions << Submission.create!(
        subject_id: package.subject_id,
        package_id: package.id,
        package_subfolder: row['subfolder'],
        recipient_uri: row['recipient_uri'],
        posp_id: row['posp_id'],
        posp_version: row['posp_version'],
        message_type: row['message_type'],
        message_subject: row['message_subject'],
        sender_business_reference: row['sender_business_reference'],
        recipient_business_reference: row['recipient_business_reference'],
        message_id: uuid,
        correlation_id: uuid
      )
    end

    submissions
  end

  delegate :uuid, to: self
end
