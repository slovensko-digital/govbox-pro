require "test_helper"

class AutomationRuleFormTest < ActiveSupport::TestCase
  class FormPreparation
    include AutomationRuleForm

    def prepare(rule)
      prepare_condition_fields(rule)
      prepare_action_fields(rule)
    end
  end

  test "prepares defaults before rendering without saving the rule" do
    rule = Automation::Rule.new(conditions: [Automation::Condition.new], actions: [Automation::Action.new])

    FormPreparation.new.prepare(rule)

    assert_equal Automation::Condition::ATTR_LIST.first.to_s, rule.conditions.first.attr
    assert_equal rule.conditions.first.valid_condition_type_list_for_attr.first, rule.conditions.first.type
    assert_equal Automation::Action::ACTION_LIST.first, rule.actions.first.type
    assert_not rule.persisted?
    assert_not rule.conditions.first.persisted?
  end

  test "keeps the selected condition and action" do
    condition = Automation::Condition.new(attr: "title", type: "Automation::ContainsCondition")
    action = Automation::Action.new(type: Automation::Action::ACTION_LIST.last)
    rule = Automation::Rule.new(conditions: [condition], actions: [action])

    FormPreparation.new.prepare(rule)

    assert_equal "title", condition.attr
    assert_equal "Automation::ContainsCondition", condition.type
    assert_equal Automation::Action::ACTION_LIST.last, action.type
  end
end
