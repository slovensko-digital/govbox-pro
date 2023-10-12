class Upvs::FormBuilder
  GENERAL_AGENDA_SCHEMA ||= 'http://schemas.gov.sk/form/App.GeneralAgenda/1.9'

  def self.parse_xml_identifier(xml)
    xml = delete_extra_whitespaces(xml)
    xml_doc = Nokogiri::XML(xml)

    xml_doc.root&.namespace&.href
  end

  def self.build_general_agenda_xml(subject:, body:)
    <<~GENERAL_AGENDA
      <GeneralAgenda xmlns="#{GENERAL_AGENDA_SCHEMA}">
        <subject>#{subject}</subject>
        <text>#{body}</text>
      </GeneralAgenda>
    GENERAL_AGENDA
  end

  def self.parse_general_agenda_text(general_agenda_xml)
    general_agenda_xml = delete_extra_whitespaces(general_agenda_xml)
    xml_doc = Nokogiri::XML(general_agenda_xml)

    xml_doc.at('text')&.text
  end

  private

  def self.delete_extra_whitespaces(xml)
    xml.gsub(/\\n/, '').gsub(/>\s*/, ">").gsub(/\s*</, "<")
  end
end
