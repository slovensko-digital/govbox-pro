# frozen_string_literal: true

class Settings::Rules::ConditionFormComponent < ViewComponent::Base
  def initialize(form:, index:, enabled: true)
    @form = form
    @index = index
    @enabled = enabled
  end

  def before_render
    @condition_type_list = Automation::Condition.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
    # TODO: Toto som chcel vytiahnut ako ENUM, nepodarilo sa
    @attr_list = [
      [t('sender_name'), 'sender_name'],
      [t('recipient_name'), 'recipient_name'],
      [t('sender_uri'), 'sender_uri'],
      [t('recipient_uri'), 'recipient_uri']
    ]
  end
end
