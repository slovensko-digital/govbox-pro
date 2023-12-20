class Archivation::ExtendArchivedObjectJob < ApplicationJob
  @api = ArchiverEnvironment.archiver_client.api

  def perform(archived_object)
    content = object_content_to_extend(archived_object)
    return unless content

    extended_document = @api.extend_document(content)
    validation_response = @api.validate_document(Base64.strict_decode64(extended_document))
    archived_object_version = ArchivedObjectVersion.new(content: Base64.strict_decode64(extended_document), valid_to: last_archive_timestamp(validation_response), validation_result: validation_result_code(validation_response), archived_object: archived_object)
    archived_object_version.save
  end

  private

  def object_content_to_extend(archived_object)
    unless archived_object.archived_object_versions.empty?
      return nil unless archived_object.archived_object_versions.last.validation_result == '0'

      return archived_object.archived_object_versions.last.content
    end

    return nil unless archived_object.validation_result == '0'

    archived_object.message_object.content
  end

  def last_archive_timestamp(validation_response)
    result = DateTime.parse('1970-01-01')
    validation_response['signatures'].each do |s|
      s['signatureInfo']['timestamps'].each do |t|
        result = DateTime.parse(t['notAfter']) if (t['timestampType'] == 'DOCUMENT_TIMESTAMP' || t['timestampType'] == 'ARCHIVE_TIMESTAMP') && DateTime.parse(t['notAfter']) > result
      end
    end

    result
  end

  def validation_result_code(validation_response)
    result = -1
    validation_response['signatures'].each do |s|
      result = s['validationResult']['code'] if s['validationResult']['code'] > result
    end

    result
  end
end
