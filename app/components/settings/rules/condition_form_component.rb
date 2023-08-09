# frozen_string_literal: true

class Settings::Rules::ConditionFormComponent < ViewComponent::Base
  def initialize(condition_form:, rule_form:)
    @condition_form = condition_form
    # TODO: testik
    @condition_form.id = @condition_form.id.to_i if @condition_form.id
    @rule_form = rule_form
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
