class Settings::Rules::ActionsFormComponent < ViewComponent::Base
  def initialize(automation_rule:)
    @automation_rule = automation_rule
    @new_rule = Automation::Rule.new(actions: [Automation::Action.new])
  end
end
