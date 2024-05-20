class FillMissingInformationInNestedMessageObjects < ActiveRecord::Migration[7.1]
  def up
    NestedMessageObject.where(mimetype: 'application/octet-stream').find_each do |nested_message_object|
      manifest_file_content = ::SignedAttachment::Asice.get_manifest_file_content(nested_message_object.message_object.content)

      next unless manifest_file_content.present?

      xml_manifest = Nokogiri::XML(manifest_file_content)

      mimetype_from_manifest = xml_manifest.xpath("//manifest:file-entry[@manifest:full-path = '#{nested_message_object.name}']/@manifest:media-type")&.first&.value

      next unless mimetype_from_manifest.present?

      nested_message_object.mimetype = mimetype_from_manifest
      nested_message_object.name += Utils.file_extension_by_mime_type(nested_message_object.mimetype).to_s if Utils.file_name_without_extension?(nested_message_object))

      nested_message_object.save
    end
  end
end
