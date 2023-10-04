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

    with_file_entries_from_content(content) do |entry|
      next if should_skip_entry?(entry)

      payload_document = PayloadDocument.new
      payload_document.name = entry.name
      payload_document.content = entry.content
      payload_document.mimetype = Utils.detect_mime_type(entry_name: entry.name)
      payload_documents << payload_document
    end

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
end
