require 'csv'

class Drafts::ParseImportJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(import, import_zip_path, jobs_batch: GoodJob::Batch.new, load_content_job: Drafts::LoadContentJob, on_success_job: Drafts::FinishImportJob)
    extracted_import_path = File.join(Utils.file_directory(import_zip_path), File.basename(import_zip_path, ".*"))
    system("unzip", import_zip_path, '-d', extracted_import_path)

    import.update(content_path: extracted_import_path)

    raise "Invalid import" unless import.valid?

    csv_paths = Dir[extracted_import_path + "/*.csv"]

    drafts_from_csv = load_import_csv(import, csv_paths.first)
    drafts_from_folders = []

    Dir.each_child(extracted_import_path) do |entry_name|
      if File.directory?(File.join(extracted_import_path, entry_name))
        draft = Draft.find_or_create_by!(
          subject_id: import.subject.id,
          import_id: import.id,
          import_subfolder: File.basename(entry_name)
        )
        draft.update(status: "being_loaded")
        drafts_from_folders << draft

        jobs_batch.add do
          load_content_job.perform_later(draft, File.join(extracted_import_path, entry_name))
        end
      end
    end

    all_drafts = (drafts_from_csv + drafts_from_folders).uniq
    jobs_batch.enqueue(on_success: on_success_job, import: import, drafts: all_drafts, zip_path: import_zip_path, extracted_data_path: extracted_import_path)

    import.update(status: "parsed")
  rescue
    # TODO Send notification
    import.destroy!
  end

  private

  def load_import_csv(import, csv_path)
    drafts = []

    csv_options = {
      encoding: 'UTF-8',
      col_sep: File.open(csv_path) { |f| f.readline }.include?(';') ? ';' : ',',
      headers: true
    }

    CSV.parse(File.read(csv_path), **csv_options) do |row|
      drafts << Draft.create!(
        subject_id: import.subject_id,
        import_id: import.id,
        import_subfolder: row['subfolder'],
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

    drafts
  end

  delegate :uuid, to: self
end
