module Utils
  class FsInformationParser
    # TODO
    FILE_NAME_REGEXP = /^[^_]*/

    def parse_info_from_filename(filename)
      FILE_NAME_REGEXP.match(filename)&.captures
    end
  end
end
