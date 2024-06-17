require 'csv'

class Upvs::Drafts::ParseImportJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  DEFAULT_SKTALK_CLASS = 'EGOV_APPLICATION'

  def perform(import, author:, jobs_batch: GoodJob::Batch.new, load_content_job: Upvs::Drafts::LoadContentJob, on_success_job: Upvs::Drafts::FinishImportJob)
    extracted_import_path = unzip_import(import)

    raise "Invalid import" unless import.valid?

    csv_paths = Dir[extracted_import_path + "/*.csv"]

    ActiveRecord::Base.transaction do
      load_import_csv(import, csv_paths.first, author: author)

      Dir.each_child(extracted_import_path) do |entry_name|
        if File.directory?(File.join(extracted_import_path, entry_name))
          message_draft = Upvs::MessageDraft.where(import: import).where("metadata ->> 'import_subfolder' = ?", File.basename(entry_name)).take

          unless message_draft
            message_draft = create_draft_with_thread(import, message_subject: File.basename(entry_name), author: author)
          end

          jobs_batch.add do
            load_content_job.perform_later(message_draft, File.join(extracted_import_path, entry_name))
          end
        end
      end

      jobs_batch.enqueue(on_success: on_success_job, import: import)

      import.parsed!
    end
  rescue
    # TODO Send notification
    Utils.delete_file(import.content_path)
    import.destroy!
  end

  private

  def unzip_import(import)
    import_zip_path = import.content_path
    extracted_import_path = File.join(Utils.file_directory(import_zip_path), File.basename(import_zip_path, ".*"))

    system("unzip", import_zip_path, '-d', extracted_import_path)
    Utils.delete_file(import_zip_path)

    import.update(content_path: extracted_import_path)
    import.unzipped!

    extracted_import_path
  end

  def load_import_csv(import, csv_path, author:)
    csv_options = {
      encoding: 'UTF-8',
      col_sep: File.open(csv_path) { |f| f.readline }.include?(';') ? ';' : ',',
      headers: true
    }
    
    CSV.parse(File.read(csv_path), **csv_options) do |row|
      message_draft = create_draft_with_thread(import, message_subject: row['message_subject'], author: author)
      load_message_draft_metadata(message_draft, row)

      tags = JSON.parse(row["tags"]) if row["tags"]
      tags&.each do |tag_name|
        message_draft.add_cascading_tag(
          import.box.tenant.tags.find_or_create_by!(name: tag_name) do |tag|
            tag.type = SimpleTag.to_s
          end
        )
      end
    end
  end

  def create_draft_with_thread(import, message_subject:, author:)
    message_thread = import.box.message_threads.create(
      title: message_subject,
      original_title: message_subject,
      delivered_at: Time.now,
      last_message_delivered_at: Time.now
    )

    Upvs::MessageDraft.create(
      uuid: uuid,
      thread: message_thread,
      title: message_subject,
      replyable: false,
      sender_name: import.box.name,
      outbox: true,
      read: false,
      delivered_at: Time.now,
      import: import,
      author: author,
      metadata: {
        "correlation_id": uuid,
        "status": "being_loaded"
      }
    )
  end

  def load_message_draft_metadata(message_draft, row)
    message_draft.metadata.merge!({
        "recipient_uri": row['recipient_uri'],
        "posp_id": row['posp_id'],
        "posp_version": row['posp_version'],
        "message_type": row['message_type'],
        "sender_business_reference": row['sender_business_reference'],
        "recipient_business_reference": row['recipient_business_reference'],
        "import_subfolder": row['subfolder'],
      }
    )
    message_draft.save
  end

  delegate :uuid, to: self
end
