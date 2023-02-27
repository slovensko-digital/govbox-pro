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
end
