require 'test_helper'

class Automation::RuleTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
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

  test 'should run an automation on message created AttachmentContainsConidition AddMessageThreadTagAction AddMessageExportMetadataBoxNameAction' do
    govbox_message = govbox_messages(:ssd_crac)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    assert_includes message.thread.tags, tags(:ssd_crac_success)
    assert_not_includes message.tags, tags(:ssd_crac_success)
    assert_equal "BOX NAME", message.export_metadata["box_name"]
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

  test 'should run an automation on message - adds s Potvrdenkou tag if conditions satisfied' do
    tag = tags(:accountants_s_potvrdenkou)
    message_thread = message_threads(:ssd_main_done)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    assert_not_includes message_thread.tags, tag

    Automation::ApplyRulesForEventJob.perform_later("message_created", inbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    assert_includes inbox_message.thread.tags.reload, tag
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

  test 'should run an automation on message created ApiConnectionCondition AddMessageThreadTagAction' do
    author = users(:accountants_basic)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :post_validation, {
      "status" => 202,
      "body" => nil,
      "headers" => {}
    },
    ["716_626", Base64.strict_encode64(file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read)]

    FsEnvironment.fs_client.stub :api, fs_api do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message_draft = Fs::MessageDraft.last
    assert_includes message_draft.thread.tags, tags(:api_connection_tag)
  end

  test 'should run an automation on message created AuthorHasApiConnectionCondition ValueCondition AddSignatureRequestedFromAuthorMessageThreadTagAction (if author has API connection for the box)' do
    author = users(:accountants_user2)
    signature_requested_from_author_tag = tags(:accountants_user2_signature_requested)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "9988665533",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :post_validation, {
      "status" => 202,
      "body" => nil,
      "headers" => {}
    },
    ["716_626", Base64.strict_encode64(file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read)]

    FsEnvironment.fs_client.stub :api, fs_api do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message_draft = Fs::MessageDraft.last
    assert_includes message_draft.thread.tags, signature_requested_from_author_tag
  end

  test 'should not run an automation on message created AuthorHasApiConnectionCondition ValueCondition AddSignatureRequestedFromAuthorMessageThreadTagAction (if author does not have API connection for the box)' do
    author = users(:accountants_user4)
    signature_requested_from_author_tag = tags(:accountants_user4_signature_requested)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "9988665533",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :post_validation, {
      "status" => 202,
      "body" => nil,
      "headers" => {}
    },
    ["716_626", Base64.strict_encode64(file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read)]

    FsEnvironment.fs_client.stub :api, fs_api do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message_draft = Fs::MessageDraft.last
    assert_not_includes message_draft.thread.tags, signature_requested_from_author_tag
  end

  test 'does not run an automation unless ValueCondition satisfied' do
    author = users(:accountants_basic)

    rule = automation_rules(:add_tag_api_connection)
    rule.conditions.create(type: "Automation::ValueCondition", attr: "type", value: "Message")

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :post_validation, {
      "status" => 202,
      "body" => nil,
      "headers" => {}
    },
    ["716_626", Base64.strict_encode64(file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read)]

    FsEnvironment.fs_client.stub :api, fs_api do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message_draft = Fs::MessageDraft.last
    assert_not_includes message_draft.thread.tags, tags(:api_connection_tag)
  end

  test 'runs an automation if ValueCondition satisfied' do
    author = users(:accountants_basic)

    rule = automation_rules(:add_tag_api_connection)
    rule.conditions.create(type: "Automation::ValueCondition", attr: "type", value: "Fs::MessageDraft")

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :post_validation, {
      "status" => 202,
      "body" => nil,
      "headers" => {}
    },
    ["716_626", Base64.strict_encode64(file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read)]

    FsEnvironment.fs_client.stub :api, fs_api do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message_draft = Fs::MessageDraft.last
    assert_includes message_draft.thread.title, "1122334455"
  end
end
