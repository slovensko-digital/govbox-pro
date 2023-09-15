class Settings::Rules::RuleHeaderFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
  def before_render
    @trigger_events_list = [[t('message_created'), 'message_created']]
  end
end
