require "test_helper"

class Automation::ActionTest < ActiveSupport::TestCase
  setup do
    @rule = automation_rules(:two)
  end

  test "tag actions require a tag" do
    assert @rule.actions.build(type: "Automation::AddMessageThreadTagAction", action_object: tags(:ssd_finance)).valid?

    action = @rule.actions.build(type: "Automation::UnassignMessageThreadTagAction")

    assert_not action.valid?
    assert action.errors.added?(:action_object, :blank)
  end

  test "tag actions reject other objects" do
    action = @rule.actions.build(type: "Automation::AddMessageThreadTagAction", action_object: automation_webhooks(:one))

    assert_not action.valid?
    assert action.errors.added?(:action_object_type, :inclusion, value: "Automation::Webhook")
  end

  test "webhook action rejects other objects" do
    action = @rule.actions.build(type: "Automation::FireWebhookAction", action_object: tags(:ssd_finance))

    assert_not action.valid?
    assert action.errors.added?(:action_object_type, :inclusion, value: "Tag")
  end

  test "webhook action requires a webhook" do
    action = @rule.actions.build(type: "Automation::FireWebhookAction")

    assert_not action.valid?
    assert action.errors.added?(:action_object, :blank)
  end
end
