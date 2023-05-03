require 'csv'

class SubmissionPackages::ParsePackageJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(package, package_zip_path, load_submission_content_job: Submissions::LoadSubmissionContentJob)
    extracted_package_path = File.join(Utils.file_directory(package_zip_path), File.basename(package_zip_path, ".*"))
    system("unzip", package_zip_path, '-d', extracted_package_path)

    validate_package_structure(extracted_package_path)

    csv_paths = Dir[extracted_package_path + "/*.csv"]

    raise "Package must contain 1 CSV file!" if csv_paths.size != 1

    load_package_csv(package, csv_paths.first)

    jobs_batch = GoodJob::Batch.new

    Dir.each_child(extracted_package_path) do |entry_name|
      if File.directory?(File.join(extracted_package_path, entry_name))
        submission = Submission.find_or_create_by(
          package_id: package.id,
          package_subfolder: File.basename(entry_name)
        )
        submission.update(status: "being_loaded")

        jobs_batch.add do
          load_submission_content_job.perform_later(submission, File.join(extracted_package_path, entry_name))
        end
      end
    end

    jobs_batch.enqueue(on_success: SubmissionPackages::CleanPackageFilesJob, package: package, zip_path: package_zip_path, extracted_data_path: extracted_package_path)

    package.update(status: "parsed")
  rescue StandardError => e
    # TODO Send notification
    package.destroy!
  end

  private

  def load_package_csv(package, csv_path)
    csv_options = {
      encoding: 'UTF-8',
      col_sep: File.open(csv_path) { |f| f.readline }.include?(';') ? ';' : ',',
      headers: true
    }

    CSV.parse(File.read(csv_path), **csv_options) do |row|
      Submission.create!(
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
  end

  def validate_package_structure(extracted_package_path)
    raise "No submissions found!" if Utils.sub_folders(extracted_package_path).empty?

    Dir.each_child(extracted_package_path) do |package_entry_name|
      package_entry_path = File.join(extracted_package_path, package_entry_name)

      if File.directory?(package_entry_path)
        # check each submission directory structure
        Dir.each_child(package_entry_path) do |submission_subfolder_name|
          submission_subfolder_path = File.join(package_entry_path, submission_subfolder_name)

          if File.directory?(submission_subfolder_path)
            case(submission_subfolder_name)
            when 'podpisane', 'podpisat', 'nepodpisovat'
              contains_files_only?(submission_subfolder_path)
            else
              raise "Disallowed submission subfolder!"
            end
          else
            raise "Unknown signature status! File must be inside a folder."
          end
        end
      elsif Utils.csv?(package_entry_name)
        # noop
      else
        raise "Package contains extra file!"
      end
    end
  end

  def contains_files_only?(path)
    Dir.each_child(path) do |entry_name|
      raise "Disallowed content subfolder!" if File.directory?(entry_name)
    end
  end

  delegate :uuid, to: self
end
