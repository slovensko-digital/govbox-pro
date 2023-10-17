module Utils
  extend self

  UUID_PATTERN = %r{\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z}
  EXTENSIONS_ALLOW_LIST = %w(pdf xml asice asics xzep zip txt doc docx jpg jpeg png tif tiff)

  def file_directory(file_path)
    File.dirname(file_path)
  end

  def sub_folders(path)
    Dir.chdir(path) do
      Dir["*"].reject { |o| not File.directory?(o) }
    end
  end
    
  def csv?(name)
    File.extname(name).downcase == '.csv'
  end

  def file_mime_type_by_name(entry_name:, is_form: false)
    case File.extname(entry_name).downcase
    when '.pdf'
      'application/pdf'
    when '.xml'
      is_form ? 'application/x-eform-xml' : 'application/xml' # TODO confirm if correct
    when '.asice'
      'application/vnd.etsi.asic-e+zip'
    when '.asics'
      'application/vnd.etsi.asic-s+zip'
    when '.xzep'
      'application/x-xades_zep' # TODO confirm if correct
    when '.zip'
      'application/x-zip-compressed'
    when '.txt'
      'text/plain'
    when '.doc'
      'application/msword'
    when '.docx'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.tiff', '.tif'
      'image/tiff'
    end
  end

  def file_extension_by_mime_type(mime_type)
    case mime_type.downcase
    when 'application/pdf'
      '.pdf'
    when 'application/xml', 'application/x-eform-xml'
      '.xml'
    when 'application/vnd.etsi.asic-e+zip'
      '.asice'
    when 'application/vnd.etsi.asic-s+zip'
      '.asics'
    when 'application/x-xades_zep'
      '.xzep'
    when 'application/x-zip-compressed'
      '.zip'
    when 'text/plain'
      '.txt'
    when 'application/msword'
      '.doc'
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      '.docx'
    when 'image/jpeg'
      '.jpg'
    when 'image/png'
      '.png'
    when 'image/tiff'
      '.tiff'
    end
  end

  # TODO use UPVS API to detect if document is signed
  def is_signed?(entry_name:, content:)

    case File.extname(entry_name).downcase
    when '.asice', '.asics', '.xzep'
      true
    when '.pdf'
      begin
        reader = PDF::Reader.new(StringIO.new(content))
      rescue StandardError
        return false # NOTE: if pdf reading fails it is not signed
      end

      reader.objects.to_a.flatten.select { |o| o.is_a?(Hash) }.select { |o| o[:Type] == :Sig }.first.present?
    else
      false
    end
  end

  def delete_file(path)
    FileUtils.rm_rf(path)
  end
end
