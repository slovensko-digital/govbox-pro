# frozen_string_literal: true

class Settings::Rules::ActionsFormComponent < ViewComponent::Base
  def initialize(rule_form: Settings::Rules::RuleForm.new)
    @rule_form = rule_form
  end

  def before_render
    @action_type_list = Automation::Action.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
  end
end
