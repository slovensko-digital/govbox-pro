require "test_helper"

class Automation::ActionTest < ActiveSupport::TestCase
  setup do
    @rule = automation_rules(:two)
  end

  test "tag action requires a tag of the rule's tenant" do
    assert @rule.actions.build(type: "Automation::AddMessageThreadTagAction", action_object: tags(:ssd_finance)).valid?

    [nil, tags(:solver_special), automation_webhooks(:one)].each do |object|
      action = @rule.actions.build(type: "Automation::UnassignMessageThreadTagAction", action_object: object)

      assert_not action.valid?, "expected #{object.inspect} to be rejected"
      assert_equal ["must be a tag of the same tenant"], action.errors[:action_object]
    end
  end

  test "webhook action requires a webhook of the rule's tenant" do
    action = @rule.actions.build(type: "Automation::FireWebhookAction", action_object: tags(:ssd_finance))

    assert_not action.valid?
    assert_equal ["must be a webhook of the same tenant"], action.errors[:action_object]
  end
end
