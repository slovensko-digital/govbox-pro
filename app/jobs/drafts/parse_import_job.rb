require 'csv'

class Drafts::ParseImportJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(import, author: , jobs_batch: GoodJob::Batch.new, load_content_job: Drafts::LoadContentJob, on_success_job: Drafts::FinishImportJob)
    extracted_import_path = unzip_import(import)

    raise "Invalid import" unless import.valid?

    csv_paths = Dir[extracted_import_path + "/*.csv"]

    ActiveRecord::Base.transaction do
      load_import_csv(import, csv_paths.first, author: author)

      Dir.each_child(extracted_import_path) do |entry_name|
        if File.directory?(File.join(extracted_import_path, entry_name))

          message_draft = MessageDraft.where(import: import).where("metadata ->> 'import_subfolder' = ?", File.basename(entry_name)).take

          unless message_draft
            MessageDraft.create(
              uuid: uuid,
              thread: thread,
              title: File.basename(entry_name),
              replyable: false,
              read: true,
              delivered_at: Time.now,
              import: import,
              author: author,
              metadata: {
                "import_subfolder": File.basename(entry_name),
                "status": "being_loaded"
              }
            )
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
    
    folder = Folder.find_or_create_by!(
      box: import.box,
      name: "Drafts"
    )
    
    CSV.parse(File.read(csv_path), **csv_options) do |row|
      message_thread = folder.message_threads.create(
        folder: folder,
        title: row['message_subject'],
        original_title: row['message_subject'],
        delivered_at: Time.now,
        last_message_delivered_at: Time.now
      )

      drafts_tag = Tag.find_or_create_by!(name: "Drafts", tenant: import.box.tenant)
      message_thread.add_tag(drafts_tag)
      
      MessageDraft.create!(
        uuid: uuid,
        thread: message_thread,
        title: row['message_subject'],
        replyable: false,
        read: false,
        delivered_at: Time.now,
        import: import,
        author: author,
        metadata: {
          "recipient_uri": row['recipient_uri'],
          "posp_id": row['posp_id'],
          "posp_version": row['posp_version'],
          "message_type": row['message_type'],
          "correlation_id": uuid,
          "sender_business_reference": row['sender_business_reference'],
          "recipient_business_reference": row['recipient_business_reference'],
          "import_subfolder": row['subfolder'],
          "status": "being_loaded"
        }
      )
    end
  end

  delegate :uuid, to: self
end
