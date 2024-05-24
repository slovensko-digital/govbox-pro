module Utils
  class FsInformationParser
    FILE_NAME_REGEXP = /dic(\d+)_fs([a-zA-Z0-9_-]+?)__/

    def self.parse_info_from_filename(filename)
      FILE_NAME_REGEXP.match(filename)&.captures
    end
  end
end
