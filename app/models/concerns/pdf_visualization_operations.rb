# frozen_string_literal: true

module PdfVisualizationOperations
  extend ActiveSupport::Concern

  UPVS_FORM_IDENTIFIER_PATTERN = /([^\/]+)\/(\d+\.\d+)\z/

  included do
    def prepare_pdf_visualization
      prepare_pdf_visualization_from_template || prepare_pdf_visualization_from_html
    end

    def prepare_pdf_visualization_from_template
      return unless form&.xsl_fo
      return unless unsigned_content
      return unless xml?

      begin
        xml_file = Tempfile.new("#{id}.xml")
        xml_file.write(xml_unsigned_content)
        xml_file.rewind

        xsl_file = Tempfile.new("#{id}.fo.xsl")
        xsl_file.write(form.xsl_fo.to_s)
        xsl_file.rewind

        pdf_file = Tempfile.new("#{id}.pdf")

        success = system "fop -xml #{xml_file.path} -c #{Rails.root + 'config/apache_fop/fop.xconf'} -xsl #{xsl_file.path} -pdf #{pdf_file.path}"

        if success
          pdf_file.rewind
          pdf_file.read
        end
      ensure
        xml_file.close
        xsl_file.close
        pdf_file.close

        xml_file.unlink
        xsl_file.unlink
        pdf_file.unlink
      end
    end

    def prepare_pdf_visualization_from_html
      return unless form?
      return unless message.html_visualization.present?

      Grover.new(full_html_document_from_body_content(message.html_visualization), format: 'A4', margin: {top: '15px', bottom: '15px', left: '15px', right: '15px'}).to_pdf
    end

    def xml_unsigned_content
      document = Nokogiri::XML(unsigned_content) do |config|
        config.noblanks
      end
      document = Nokogiri::XML(document.xpath('*:XMLDataContainer/*:XMLData/*').to_xml) do |config|
        config.noblanks
      end if document.xpath('*:XMLDataContainer/*:XMLData').any?

      document
    end

    def form
      return unless xml?

      xml_document = xml_unsigned_content
      posp_id, posp_version = xml_document&.root&.namespace&.href&.match(UPVS_FORM_IDENTIFIER_PATTERN)&.captures

      ::Upvs::Form.find_by(
        identifier: posp_id,
        version: posp_version
      ) if posp_id && posp_version
    end

    def find_or_create_form
      return unless xml?

      xml_document = xml_unsigned_content
      posp_id, posp_version = xml_document&.root&.namespace&.href&.match(UPVS_FORM_IDENTIFIER_PATTERN)&.captures

      ::Upvs::Form.find_or_create_by(
        identifier: posp_id,
        version: posp_version
      ) if posp_id && posp_version
    end

    def downloadable_as_pdf?
      (xml? && form&.xsl_fo&.present?) || (form? && message.html_visualization.present?)
    end

    def xml?
      if is_signed?
        nested_message_objects&.where("mimetype ILIKE ANY ( array[?] )", Utils::XML_MIMETYPES.map {|val| "#{val}%" })&.any?
      else
        Utils::XML_MIMETYPES.any? { |xml_mimetype| xml_mimetype == Utils.mimetype_without_optional_params(mimetype) }
      end
    end

    def full_html_document_from_body_content(body_content)
      <<-HTML
      <html>
        <head>
            <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        </head>
        <body>
          #{body_content}
        </body>
      </html>
    HTML
    end
  end
end
