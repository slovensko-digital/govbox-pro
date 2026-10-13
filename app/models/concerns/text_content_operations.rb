module TextContentOperations
  # memoized, so that automation rules evaluated against the same object don't parse it repeatedly
  def text_content
    return @text_content if defined?(@text_content)

    @text_content = if pdf?
                      pdf_text_content
                    elsif xml?
                      # TODO: fix encoding when saving content to DB
                      Nokogiri::XML(content, nil, 'UTF-8').to_s
                    end
  end

  private

  def pdf_text_content
    io = StringIO.new
    io.set_encoding Encoding::BINARY
    io.write content
    pdf_string = ""
    PDF::Reader.open(io) do |pdf|
      pdf_string = pdf.pages.map(&:text).join(" ")
    end
    io.close
    pdf_string
  end
end
