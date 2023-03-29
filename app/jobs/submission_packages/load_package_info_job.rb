require 'csv'

class SubmissionPackages::LoadPackageInfoJob < ApplicationJob
  queue_as :high_priority

  class << self
    delegate :uuid, to: SecureRandom
  end

  CSV_OPTIONS = {
    encoding: 'UTF-8',
    col_sep: ',',
    headers: true
  }

  def perform(package, csv_path)
    CSV.parse(File.read(csv_path), **CSV_OPTIONS) do |row|
      submission = Submission.find_or_create_by!(
        package_id: package.id,
        package_subfolder: row['subfolder']
      )

      submission.update!(
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

  delegate :uuid, to: self
end
