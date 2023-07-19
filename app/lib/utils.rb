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

  def detect_mime_type(entry_name:, is_form: false)
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
    else
      raise "Uknown MimeType for #{entry_name}"
    end
  end

  def delete_file(path)
    FileUtils.rm_rf(path)
  end
end
