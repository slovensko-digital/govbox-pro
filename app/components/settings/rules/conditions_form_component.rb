class Settings::Rules::ConditionsFormComponent < ViewComponent::Base
  def initialize(automation_rule:)
    @automation_rule = automation_rule
    @new_rule = Automation::Rule.new(conditions: [Automation::Condition.new])
  end
end
