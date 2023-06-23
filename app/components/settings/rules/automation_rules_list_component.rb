# frozen_string_literal: true

class Settings::Rules::AutomationRulesListComponent < ViewComponent::Base
  renders_many :automation_rules
end
