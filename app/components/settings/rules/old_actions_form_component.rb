# frozen_string_literal: true

class Settings::Rules::ActionsFormComponent < ViewComponent::Base
  def initialize(automation_rule:)
    @automation_rule = automation_rule
  end

  def before_render
    @action_type_list = Automation::Action.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
  end
end
