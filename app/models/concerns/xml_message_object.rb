# frozen_string_literal: true

module XmlMessageObject
  extend ActiveSupport::Concern

  included do
    def xml?
      if try(:is_signed)
        nested_message_objects&.where(mimetype: Utils::XML_MIMETYPES)&.any?
      else
        mimetype.in?(Utils::XML_MIMETYPES)
      end
    end

    def pdf_transformation
    return unless message.upvs_form&.xsl_fo
    return unless unsigned_content
    return unless xml?

    document = Nokogiri::XML(unsigned_content) do |config|
      config.noblanks
    end
    document = Nokogiri::XML(document.xpath('*:XMLDataContainer/*:XMLData/*').to_xml) do |config|
      config.noblanks
    end if document.xpath('*:XMLDataContainer/*:XMLData').any?

    template = Nokogiri::XSLT(message.upvs_form.xsl_fo)
    fo_xml = template.transform(document)
    fo_xml.encoding = 'UTF-8'

    begin
      fo_xml_file = Tempfile.new("#{id}.fo.xml")
      fo_xml_file.write(fo_xml.to_s)
      fo_xml_file.rewind
      pdf_file = Tempfile.new("#{id}.pdf", :encoding => 'UTF-8')

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
  end
end
