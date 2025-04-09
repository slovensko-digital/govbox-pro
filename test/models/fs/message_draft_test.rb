# frozen_string_literal: true

require "test_helper"

class Fs::MessageDraftTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  test "create_and_validate_with_fs_form method schedules Fs::ValidateMessageDraftJob" do
    author = users(:accountants_basic)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_enqueued_with(job: Fs::ValidateMessageDraftJob) do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
      end
    end

    message_draft = Fs::MessageDraft.last
    assert message_draft.form_object.tags.include?(author.tenant.signer_group.signature_requested_from_tag)
    assert message_draft.thread.tags.include?(author.tenant.signer_group.signature_requested_from_tag)
  end

  test "create_and_validate_with_fs_form method strips DIC (matches box even if extra spaces within DIC in XML file)" do
    author = users(:accountants_basic)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455          ",
      "form_identifier" => "795_777"
    },
    [file_fixture("fs/Accountants_main_FS_prehlad_0924.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/Accountants_main_FS_prehlad_0924.xml", "application/xml")], author: author)
    end

    message_draft = Fs::MessageDraft.last
    assert message_draft.thread.box.eql?(boxes(:fs_accountants))
  end

  test "create_and_validate_with_fs_form method does not raise if XML does not match any FS form" do
    author = users(:accountants_basic)

    fs_api_handler = Minitest::Mock.new
    fs_api_handler.expect :public_send, OpenStruct.new(status: 404, headers: nil, body: "null"), [:post, 'https://fsapi.test/api/v1/forms/parse', {:content=> Base64.strict_encode64(file_fixture("fs/random_xml.xml").read) }]

    fs_api_handler_options = Minitest::Mock.new
    fs_api_handler.expect :options, fs_api_handler_options, []
    fs_api_handler_options.expect :timeout=, nil, [900000]

    assert_nothing_raised do
      FsEnvironment.fs_client.stub :api, Fs::Api.new(ENV.fetch('FS_API_URL'), handler: fs_api_handler ) do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/random_xml.xml", "application/xml")], author: author)
      end
    end
  end

  test "create_and_validate_with_fs_form method fires EventBus" do
    author = users(:accountants_basic)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]

    subscriber1 = Minitest::Mock.new
    subscriber1.expect :perform_later, true, [:message_thread_created, MessageThread]

    subscriber2 = Minitest::Mock.new
    subscriber2.expect :perform_later, true, [:message_created, Fs::MessageDraft]

    EventBus.subscribe_job(:message_thread_created, subscriber1)
    EventBus.subscribe_job(:message_created, subscriber2)

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: author)
    end

    assert_mock subscriber1
    assert_mock subscriber2

    # remove callback
    EventBus.class_variable_get(:@@subscribers_map)[:message_thread_created].pop
    EventBus.class_variable_get(:@@subscribers_map)[:message_created].pop
  end
end
