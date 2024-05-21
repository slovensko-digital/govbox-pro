class SignedAttachment::Asice
  extend SignedAttachment

  class PayloadDocument
    attr_accessor :name, :content, :mimetype
  end

  class FileEntry
    def initialize(zip_entry)
      @zip_entry = zip_entry
    end

    def name
      @zip_entry.name.force_encoding('UTF-8')
    end

    def content
      @zip_entry.get_input_stream.read
    end

    def directory?
      @zip_entry.directory?
    end
  end

  def self.can_parse_content?(content)
    with_file_entries_from_content(content) do |entry|
      return true if entry.name =~ /\AMETA-INF\//
      return true if entry.name == 'mimetype'
    end

    false
  rescue Zip::Error
    false
  end
  
  def self.extract_documents_from_content(content)
    payload_documents = []
    manifest_file_content = nil

    with_file_entries_from_content(content) do |entry|
      manifest_file_content = entry.content if entry.name == 'META-INF/manifest.xml'

      next if should_skip_entry?(entry)

      payload_document = PayloadDocument.new
      payload_document.name = entry.name
      payload_document.content = entry.content
      payload_document.mimetype = Utils.file_mimetype_by_name(entry_name: entry.name)
      payload_documents << payload_document
    end

    fill_missing_information_from_manifest(payload_documents, manifest_file_content) if manifest_file_content

    payload_documents
  end

  def self.should_skip_entry?(entry)
    return true if entry.directory?
    return true if entry.name =~ /\AMETA-INF\//
    return true if entry.name == 'mimetype'
  end

  def self.with_file_entries_from_content(content)
    with_tmp_file_from_content(content) do |tmp_file|
      Zip::File.open(tmp_file) do |asice_zip|
        asice_zip.each do |zip_entry|
          yield FileEntry.new(zip_entry)
        end
      end
    end
  end

  def self.fill_missing_information_from_manifest(payload_documents, manifest_file_content)
    xml_manifest = Nokogiri::XML(manifest_file_content)

    payload_documents.each do |payload_document|
      next unless Utils.mimetype_without_optional_params(payload_document.mimetype) == Utils::OCTET_STREAM_MIMETYPE

      mimetype_from_manifest = xml_manifest.xpath("//manifest:file-entry[@manifest:full-path = '#{payload_document.name}']/@manifest:media-type")&.first&.value

      next unless mimetype_from_manifest.present?

      payload_document.mimetype = mimetype_from_manifest
      payload_document.name += Utils.file_extension_by_mimetype(payload_document.mimetype).to_s if Utils.file_name_without_extension?(payload_document)
    end
  end

  def self.get_manifest_file_content(content)
    manifest_file_content = nil

    with_file_entries_from_content(content) do |entry|
      manifest_file_content = entry.content if entry.name == 'META-INF/manifest.xml'
    end

    manifest_file_content
  end
end
