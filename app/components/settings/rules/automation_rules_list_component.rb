class Settings::Rules::AutomationRulesListComponent < ViewComponent::Base
  renders_many :automation_rules
  renders_one :blank_results_area
end
