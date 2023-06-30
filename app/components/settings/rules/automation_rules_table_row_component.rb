# frozen_string_literal: true

class Settings::Rules::AutomationRulesTableRowComponent < ViewComponent::Base
  def initialize(automation_rule)
    @automation_rule = automation_rule
  end
end
