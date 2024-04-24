# frozen_string_literal: true

module XmlMessageObject
  extend ActiveSupport::Concern

  FORM_IDENTIFIER_PATTERN = /([^\/]+)\/(\d+\.\d+)\z/

  included do
    def pdf_transformation
      return unless upvs_form&.xsl_fo
      return unless unsigned_content
      return unless xml?

      template = Nokogiri::XSLT(upvs_form.xsl_fo)
      fo_xml = template.transform(xml_unsigned_content)
      fo_xml.encoding = 'UTF-8'

      begin
        fo_xml_file = Tempfile.new("#{id}.fo.xml")
        fo_xml_file.write(fo_xml.to_s)
        fo_xml_file.rewind
        pdf_file = Tempfile.new("#{id}.pdf", encoding: 'UTF-8')

        system "fop -fo #{fo_xml_file.path} -pdf #{pdf_file.path}"

        pdf_file.rewind
        pdf_file.read
      ensure
        fo_xml_file.close
        pdf_file.close
        fo_xml_file.unlink
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
      xml_document = xml_unsigned_content
      posp_id, posp_version = xml_document.root.namespace&.href&.match(FORM_IDENTIFIER_PATTERN).captures

      ::Upvs::Form.find_by(
        identifier: posp_id,
        version: posp_version
      )
    end

    def xml?
      if try(:is_signed)
        nested_message_objects&.where(mimetype: Utils::XML_MIMETYPES)&.any?
      else
        mimetype.in?(Utils::XML_MIMETYPES)
      end
    end
  end
end
