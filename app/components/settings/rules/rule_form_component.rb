class Settings::Rules::RuleFormComponent < ViewComponent::Base
  def initialize(automation_rule:, notice:)
    @automation_rule = automation_rule
    @notice = notice
  end
end
