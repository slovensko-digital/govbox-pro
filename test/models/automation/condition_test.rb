require "test_helper"

class Automation::ConditionTest < ActiveSupport::TestCase
  setup do
    @rule = automation_rules(:two)
  end

  test "regexp based conditions reject an invalid regular expression" do
    condition = @rule.conditions.build(type: "Automation::ContainsCondition", attr: "title", value: "faktúra (")

    assert_not condition.valid?
    assert_match "not a valid regular expression", condition.errors[:value].sole
  end

  test "regexp based conditions accept a valid regular expression" do
    condition = @rule.conditions.build(type: "Automation::AttachmentContentContainsCondition", attr: "attachment", value: "DIČ:\\s*2020\\d{6}")

    assert condition.valid?
  end

  test "box condition requires a box" do
    condition = @rule.conditions.build(type: "Automation::BoxCondition", attr: "box")

    assert_not condition.valid?
    assert condition.errors.added?(:condition_object, :blank)
  end
end
