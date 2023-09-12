class Upvs::GeneralAgendaBuilder
  GENERAL_AGENDA_SCHEMA ||= 'http://schemas.gov.sk/form/App.GeneralAgenda/1.9'

  def self.build_xml(subject:, body:)
    <<~GENERAL_AGENDA
      <GeneralAgenda xmlns="#{GENERAL_AGENDA_SCHEMA}">
        <subject>#{subject}</subject>
        <text>#{body}</text>
      </GeneralAgenda>
    GENERAL_AGENDA
  end

  def self.parse_text(general_agenda_xml)
    general_agenda_xml = delete_extra_whitespaces(general_agenda_xml)
    xml_doc = Nokogiri::XML(general_agenda_xml)
    xml_doc.at('text').text
  end

  private

  def self.delete_extra_whitespaces(xml)
    xml.gsub(/\\n/, '').gsub(/>\s*/, ">").gsub(/\s*</, "<")
  end
end
