require 'fileutils'
require 'tempfile'

module ZipUtils
  extend self

  TMP_DIR = 'tmp'

  def extract(file, only: :itself, dir: TMP_DIR)
    FileUtils.mkpath(dir)

    Zip::File.open(file) do |entries|
      entries.select(&only).map do |entry|
        f = Tempfile.new('', dir)
        o = proc { :overwrite_on_exists }
        entries.extract(entry, f.path, &o)
        yield f.path
      ensure
        f&.close!
      end
    end
  end
end
