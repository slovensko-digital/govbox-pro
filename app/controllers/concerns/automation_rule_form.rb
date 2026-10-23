module AutomationRuleForm
  private

  def prepare_condition_fields(rule)
    rule.conditions.each do |condition|
      condition.attr ||= Automation::Condition::ATTR_LIST.first
      condition.type ||= condition.valid_condition_type_list_for_attr.first
    end
  end

  def prepare_action_fields(rule)
    rule.actions.each do |action|
      action.type ||= Automation::Action::ACTION_LIST.first
    end
  end
end
