module Utils
  extend self

  EXTENSIONS_ALLOW_LIST = %w(pdf xml asice asics xzep zip txt doc docx jpg jpeg png tif tiff)

  def file_directory(file_path)
    File.dirname(file_path)
  end

  def directory?(name)
    File.extname(name).empty?
  end

  def detect_mime_type(entry)
    case File.extname(entry.name).downcase
    when '.pdf'
      'application/pdf'
    when '.xml'
      entry.form? ? 'application/x-eform-xml' : 'application/xml' # TODO confirm if correct
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
      raise "Uknown MimeType for #{entry.name}"
    end
  end
end
