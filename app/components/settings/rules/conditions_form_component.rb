class Settings::Rules::ConditionsFormComponent < ViewComponent::Base
  def initialize(automation_rule:)
    @automation_rule = automation_rule
    @new_rule = Current.tenant.automation_rules.new(conditions: [Automation::Condition.new])
  end
end
