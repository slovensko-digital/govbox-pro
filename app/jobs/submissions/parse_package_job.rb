require 'csv'

class Submissions::ParsePackageJob < ApplicationJob
  queue_as :high_priority

  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(package)
    load_submissions_csv(package)
    load_submissions_objects(package)

    valid_submissions?(package)
  end

  private

  def load_submissions_csv(package)
    submissions_csv = Submissions::Utils.extract_csv_file(package.content)

    csv_options = {
      encoding: 'UTF-8',
      col_sep: ',',
      headers: true
    }

    CSV.parse(submissions_csv, **csv_options) do |row|
      Submission.create!(
        package_id: package.id,
        recipient_uri: row['recipient_uri'],
        posp_id: row['posp_id'],
        posp_version: row['posp_version'],
        message_type: row['message_type'],
        message_subject: row['message_subject'],
        sender_business_reference: row['sender_business_reference'],
        recipient_business_reference: row['recipient_business_reference'],
        package_subfolder: row['subfolder'],
        message_id: uuid,
        correlation_id: uuid
      )
    end
  end

  def load_submissions_objects(package)
    Zip::InputStream.open(StringIO.new(package.content)) do |io|
      while entry = io.get_next_entry
        if Submissions::Utils.directory?(entry) || Submissions::Utils.csv?(entry)
          # noop
        else
          submission_subdirectory_name = entry.name.split('/', 2)&.first
          submission = Submission.find_by!(package_id: package.id, message_subject: submission_subdirectory_name)

          raise "Found no submission record in CSV for #{submission_subdirectory_name}!" unless submission

          object = Submissions::Object.create(
            submission_id: submission.id,
            uuid: uuid,
            name: Submissions::Utils.parse_entry_name(entry), # TODO
            content: io.read,
            form: form?(submission, entry)
          )
          Submissions::Utils.detect_signature_status(entry.name, object)
        end
      end
    end
  end

  def valid_submissions?(package)
    package.submissions.each do |submission|
      raise "Submission #{submission.message_subject} does not containt exactly 1 form!" unless submission.has_one_form?
    end
  end

  def form?(submission, entry)
    file_name_without_extension = File.basename(entry.name, ".*")

    # Form file must have the same name as subfolder
    file_name_without_extension == submission.package_subfolder
  end

  delegate :uuid, to: self
end
