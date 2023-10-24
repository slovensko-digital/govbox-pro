require 'test_helper'
class Automation::RuleTest < ActiveSupport::TestCase
  test 'should update condition with nested attributes and cleanup as in model' do
    automation_rule = automation_rules(:one)

    automation_rule_params = {
      'conditions_attributes' => {
        '0' => { 'id' => automation_conditions(:one).id.to_s, 'attr' => 'box', 'type' => 'Automation::BoxCondition', 'condition_object_type' => 'Box', 'condition_object_id' => boxes(:one).id.to_s }
      },
      'id' => automation_rules(:one).id.to_s, 'name' => 'testujeme', 'trigger_event' => 'message_created',
      'actions_attributes' => {
        '0' => { 'type' => 'Automation::AddMessageThreadTagAction', 'action_object_type' => 'Tag', 'action_object_id' => tags(:one).id.to_s }
      }
    }

    automation_rule.nested_update_with_cast(automation_rule_params)

    # necessary to re-read from DB due to recasting in the test
    automation_condition_one = Automation::Condition.find(automation_conditions(:one).id)

    assert_nil automation_condition_one.value
    assert_equal automation_condition_one.condition_object_id, boxes(:one).id
    assert_equal automation_condition_one.condition_object_type, 'Box'
  end

  test 'should run an automation on message created ContainsCondition AddTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.tags, tags(:three)
  end

  test 'should run an automation on message created MetadataValueCondition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:four)
    refute_includes message.tags, tags(:four)
  end

  test 'should run an automation on message created BoxCondition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:five)
    refute_includes message.tags, tags(:five)
  end
end
