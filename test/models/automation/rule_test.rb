require 'test_helper'

class Automation::RuleTest < ActiveSupport::TestCase
  test 'should update condition with nested attributes and cleanup as in model' do
    automation_rule = automation_rules(:one)

    automation_rule_params = {
      'conditions_attributes' => {
        '0' => {
          'id' => automation_conditions(:one).id.to_s,
          'attr' => 'box',
          'type' => 'Automation::BoxCondition',
          'condition_object_type' => 'Box',
          'condition_object_id' => boxes(:ssd_main).id.to_s
        }
      },
      'id' => automation_rules(:one).id.to_s,
      'name' => 'testujeme',
      'trigger_event' => 'message_created',
      'actions_attributes' => {
        '0' => {
          'type' => 'Automation::AddMessageThreadTagAction',
          'action_object_type' => 'Tag',
          'action_object_id' => tags(:ssd_finance).id.to_s
        }
      }
    }

    automation_rule.update(automation_rule_params)

    # necessary to re-read from DB due to recasting in the test
    automation_condition_one = Automation::Condition.find(automation_conditions(:one).id)

    assert_nil automation_condition_one.value
    assert_equal automation_condition_one.condition_object_id, boxes(:ssd_main).id
    assert_equal automation_condition_one.condition_object_type, 'Box'
  end

  test 'should run an automation on message created ContainsCondition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last
    message.reload

    assert_includes message.thread.tags, tags(:ssd_construction)
  end

  test 'should run an automation on message created MetadataValueCondition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:ssd_office)
    assert_not_includes message.tags, tags(:ssd_office)
  end

  test 'should run an automation on message created BoxCondition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:ssd_print)
    assert_not_includes message.tags, tags(:ssd_print)
  end

  test 'should run an automation on message created AttachmentContainsConidition AddMessageThreadTagAction' do
    govbox_message = govbox_messages(:ssd_crac)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:ssd_crac_success)
    assert_not_includes message.tags, tags(:ssd_crac_success)
  end

  test 'should run an automation on message created outbox BooleanCondition, edesk_class MessageMetadataValueNotCondition UnassignMessageThreadTagAction if conditions satisfied' do
    tag = tags(:ssd_done)
    message_thread = message_threads(:ssd_main_done)
    govbox_message = govbox_messages(:ssd_done_new)

    assert_includes message_thread.tags, tag

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    assert_not_includes message_thread.tags.reload, tag
  end

  test 'should not run an automation on message created outbox BooleanCondition, edesk_class MessageMetadataValueNotCondition UnassignMessageThreadTagAction if outbox message delivered' do
    tag = tags(:ssd_done)
    message_thread = message_threads(:ssd_main_done)
    govbox_message = govbox_messages(:ssd_outbox)

    govbox_message.update_column(:correlation_id, 'd2d6ab13-347e-49f4-9c3b-0b8390430870')

    assert_includes message_thread.tags, tag

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    assert_includes message_thread.tags, tag
  end

  test 'should not run an automation on message created outbox BooleanCondition, edesk_class MessageMetadataValueNotCondition UnassignMessageThreadTagAction if POSTING_CONFIRMATION delivered' do
    tag = tags(:ssd_done)
    message_thread = message_threads(:ssd_main_done)
    govbox_message = govbox_messages(:ssd_main_done_posting_confirmation)

    govbox_message.update_column(:correlation_id, 'd2d6ab13-347e-49f4-9c3b-0b8390430870')

    assert_includes message_thread.tags, tag

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    assert_includes message_thread.tags, tag
  end
end
