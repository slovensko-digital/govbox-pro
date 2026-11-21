class Settings::Rules::RuleHeaderFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
  def before_render
    @trigger_events_list = Automation::Rule::TRIGGER_EVENTS.map { |event| [t(event), event] }
  end
end
