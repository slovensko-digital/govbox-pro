class Settings::Rules::RuleHeaderFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
  def before_render
    @trigger_events_list = [
      [t('message_created'), 'message_created'],
      [t('message_draft_submitted'), 'message_draft_submitted'],
      [t('message_object_downloaded'), 'message_object_downloaded'],
    ]
  end
end
