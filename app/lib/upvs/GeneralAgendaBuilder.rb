class GeneralAgendaBuilder
  GENERAL_AGENDA_SCHEMA ||= 'http://schemas.gov.sk/form/App.GeneralAgenda/1.9'

  def self.build_xml(subject:, body:)
    <<~GENERAL_AGENDA
      <GeneralAgenda xmlns="#{GENERAL_AGENDA_SCHEMA}">
        <subject>#{subject}</subject>
        <text>#{body}</text>
      </GeneralAgenda>
    GENERAL_AGENDA
  end
end