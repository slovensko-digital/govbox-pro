# frozen_string_literal: true

class Settings::Rules::ActionsFormRowComponent < ViewComponent::Base
  def initialize(action_form:, rule_form:)
    @action_form = action_form
    @rule_form = rule_form
  end

  def before_render
    @action_type_list = Automation::Action.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
  end
end
