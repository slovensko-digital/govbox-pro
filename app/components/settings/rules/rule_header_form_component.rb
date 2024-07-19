class Settings::Rules::RuleHeaderFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
  def before_render
    @trigger_events_list = [
      [t('message_created'), 'message_created'],
      [t('message_thread_created'), 'message_thread_created'],
      [t('message_updated'), 'message_updated'],
      [t('message_thread_changed'), 'message_thread_changed'],
    ]
  end
end
