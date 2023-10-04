require 'zip'

module SignedAttachment
  def with_tmp_file_from_content(content)
    tmp_file = Tempfile.new
    tmp_file.binmode
    tmp_file.write(content)
    tmp_file.flush
    yield tmp_file
  ensure
    tmp_file.close
    tmp_file.unlink
  end
end
