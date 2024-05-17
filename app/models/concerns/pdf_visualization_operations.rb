# frozen_string_literal: true

module PdfVisualizationOperations
  extend ActiveSupport::Concern

  FORM_IDENTIFIER_PATTERN = /([^\/]+)\/(\d+\.\d+)\z/

  included do
    def prepare_pdf_visualization
      return unless upvs_form&.xsl_fo
      return unless unsigned_content
      return unless xml?

      begin
        xml_file = Tempfile.new("#{id}.xml")
        xml_file.write(xml_unsigned_content)
        xml_file.rewind

        xsl_file = Tempfile.new("#{id}.fo.xsl")
        xsl_file.write(upvs_form.xsl_fo.to_s)
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

    def xml_unsigned_content
      document = Nokogiri::XML(unsigned_content) do |config|
        config.noblanks
      end
      document = Nokogiri::XML(document.xpath('*:XMLDataContainer/*:XMLData/*').to_xml) do |config|
        config.noblanks
      end if document.xpath('*:XMLDataContainer/*:XMLData').any?

      document
    end

    def upvs_form
      return unless xml?

      xml_document = xml_unsigned_content
      posp_id, posp_version = xml_document&.root&.namespace&.href&.match(FORM_IDENTIFIER_PATTERN)&.captures

      ::Upvs::Form.find_by(
        identifier: posp_id,
        version: posp_version
      )
    end

    def find_or_create_upvs_form
      return unless xml?

      xml_document = xml_unsigned_content
      posp_id, posp_version = xml_document&.root&.namespace&.href&.match(FORM_IDENTIFIER_PATTERN)&.captures

      ::Upvs::Form.find_or_create_by(
        identifier: posp_id,
        version: posp_version
      ) if posp_id && posp_version
    end

    def downloadable_as_pdf?
      xml? && upvs_form&.xsl_fo&.present?
    end

    def xml?
      if is_signed?
        nested_message_objects&.where("mimetype ILIKE ANY ( array[?] )", Utils::XML_MIMETYPES.map {|val| "#{val}%" })&.any?
      else
        Utils::XML_MIMETYPES.any? { |xml_mimetype| xml_mimetype.include?(mimetype) }
      end
    end
  end
end
