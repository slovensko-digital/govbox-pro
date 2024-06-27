# frozen_string_literal: true

module ContentMatchingOperations
  extend ActiveSupport::Concern

  included do
    def content_match?(value)
      if pdf?
        pdf_match?(value)
      elsif xml?
        content.match?(value)
      end
    end

    def pdf_match?(value)
      io = StringIO.new
      io.set_encoding Encoding::BINARY
      io.write content
      last_page_text = ""
      PDF::Reader.open(io) do |pdf|
        pdf.pages.each do |page|
          if (last_page_text + " " + page.text).gsub("\n", " ").match?(value)
            io.close
            return true
          end

          last_page_text = page.text
        end
      end
      io.close
      false
    end
  end
end
