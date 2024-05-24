module Utils
  class FsInformationParser
    FILE_NAME_REGEXP = /(\d+)-(.*)-/

    def self.parse_info_from_filename(filename)
      FILE_NAME_REGEXP.match(filename)&.captures
    end
  end
end
