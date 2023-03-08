module Submissions::Utils
  extend self

  TMP_DIR = 'tmp/submissions'

  def extract_csv_file(zip_file)
    files = []

    Zip::InputStream.open(StringIO.new(zip_file)) do |io|
      while entry = io.get_next_entry
        files << io.read if csv?(entry)
      end
    end

    raise "#{files.count} CSV files in #{zip_file}" if files.count != 1

    files.first
  end

  def directory?(entry)
    entry.name.end_with?('/')
  end

  def csv?(entry)
    entry.name.end_with?('.csv')
  end

  def parse_entry_name(entry)
    entry_path = entry.name.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') # TODO problem with diacritics

    File.basename(entry_path)
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

  def detect_signature_status(full_path, object)
    if full_path.include? 'nepodpisovat'
      object.update!(
        signed: false,
        to_be_signed: false
      )
    elsif full_path.include? 'podpisat'
      object.update!(
        signed: false,
        to_be_signed: true
      )
    elsif full_path.include? 'podpisane'
      object.update!(
        signed: true,
        to_be_signed: false
      )
    else
      raise "Unknown signature status for #{full_path}"
    end
  end
end
