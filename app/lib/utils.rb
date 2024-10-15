module Utils
  extend self

  UUID_PATTERN = %r{\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z}
  EXTENSIONS_ALLOW_LIST = %w(pdf xml asice asics xzep zip txt doc docx jpg jpeg png tif tiff)

  MIMETYPES_ALLOW_LIST = %w(application/x-eform-xml application/xml application/msword application/pdf application/vnd.etsi.asic-e+zip application/vnd.etsi.asic-s+zip application/vnd.openxmlformats-officedocument.wordprocessingml.document application/x-xades_zep application/x-zip-compressed image/jpg image/jpeg text/xml image/png image/tiff application/pkix-cert)
  XML_MIMETYPES = %w(application/x-eform-xml application/xml application/vnd.gov.sk.xmldatacontainer+xml)
  ASICE_MIMETYPES = %w(application/vnd.etsi.asic-e+zip application/vnd.etsi.asic-s+zip)
  PDF_MIMETYPE = 'application/pdf'
  OCTET_STREAM_MIMETYPE = 'application/octet-stream'

  MIMETYPE_WITHOUT_OPTIONAL_PARAMS_REGEXP = /^[^;]*/

  def unzip(zipped_content)
    ActiveSupport::Gzip.decompress(zipped_content)
  end

  def file_directory(file_path)
    File.dirname(file_path)
  end

  def sub_folders(path)
    Dir.chdir(path) do
      Dir["*"].reject { |o| not File.directory?(o) }
    end
  end

  def file_name_without_extension?(object)
    object.name.present? && !object.name&.include?(file_extension_by_mimetype(object.mimetype).to_s)
  end
    
  def csv?(name)
    File.extname(name).downcase == '.csv'
  end

  def mimetype_without_optional_params(mimetype)
    MIMETYPE_WITHOUT_OPTIONAL_PARAMS_REGEXP.match(mimetype).to_s
  end

  def file_mimetype_by_name(entry_name:, is_form: false)
    case File.extname(entry_name.to_s).downcase
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
    when '.cer'
      'application/pkix-cert'
    when '.docx'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.tiff', '.tif'
      'image/tiff'
    else
      'application/octet-stream'
    end
  end

  def file_extension_by_mimetype(mimetype)
    return unless mimetype

    case mimetype_without_optional_params(mimetype)
    when 'application/pdf'
      '.pdf'
    when 'application/xml', 'application/x-eform-xml', 'application/vnd.gov.sk.xmldatacontainer+xml'
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
