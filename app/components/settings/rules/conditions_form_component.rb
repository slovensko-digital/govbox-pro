# frozen_string_literal: true

class Settings::Rules::ConditionsFormComponent < ViewComponent::Base
  def initialize(rule_form:)
    @rule_form = rule_form || Settings::Rules::RuleForm.new
  end

  def before_render
    @condition_type_list = Automation::Condition.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
    # TODO: Toto som chcel vytiahnut ako ENUM, nepodarilo sa
    @attr_list = [[t('sender_name'), 'sender_name'], [t('recipient_name'), 'recipient_name']]
  end
end
