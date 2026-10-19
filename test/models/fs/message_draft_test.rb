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

  test "create_and_validate_with_fs_form method adds period tag to thread" do
    author = users(:accountants_basic)

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "795_777",
      "period" => {
        "pretty" => "092024"
      }
    },
                  [file_fixture("fs/Accountants_main_FS_prehlad_0924.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/Accountants_main_FS_prehlad_0924.xml", "application/xml")], author: author)
    end

    message_draft = Fs::MessageDraft.last
    assert_equal message_draft.thread.tags.find_by(name: "092024").present?, true
  end

  test "create_and_validate_with_fs_form method does not add period tag to thread if it is off for the tenant" do
    author = users(:accountants_basic)
    tenant = tenants(:accountants)
    tenant.settings["assign_period_tag_to_thread"] = false
    tenant.save

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "795_777",
      "period" => {
        "pretty" => "092024"
      }
    },
                  [file_fixture("fs/Accountants_main_FS_prehlad_0924.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/Accountants_main_FS_prehlad_0924.xml", "application/xml")], author: author)
    end

    message_draft = Fs::MessageDraft.last
    assert_equal message_draft.thread.tags.find_by(name: "092024").present?, false
  end

  test "create_and_validate_with_fs_form method does not raise if XML does not match any FS form" do
    author = users(:accountants_basic)

    fs_api_handler = Minitest::Mock.new
    fs_api_handler.expect :public_send, OpenStruct.new(status: 404, headers: nil, body: "null"), [:post, 'https://fsapi.test/api/v1/forms/parse', { content: Base64.strict_encode64(file_fixture("fs/random_xml.xml").read) }]

    fs_api_handler_options = Minitest::Mock.new
    fs_api_handler.expect :options, fs_api_handler_options, []
    fs_api_handler_options.expect :timeout=, nil, [900_000]

    assert_nothing_raised do
      FsEnvironment.fs_client.stub :api, Fs::Api.new(ENV.fetch('FS_API_URL'), handler: fs_api_handler) do
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

    skip("TODO EventBus fix")

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

  test "apply_corrected_xml replaces form content, clears validation errors and re-enqueues validation" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    corrected_xml = "<CorrectedForm>fixed</CorrectedForm>"
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => { "diff_errors" => ["FS zmenil IČO"], "corrected_xml" => corrected_xml }
    ))

    assert_enqueued_with(job: Fs::ValidateMessageDraftJob) do
      assert message_draft.apply_corrected_xml
    end

    message_draft.reload
    assert_equal corrected_xml, message_draft.form_object.content
    assert_equal({}, message_draft.metadata["validation_errors"])
    assert_equal "being_validated", message_draft.metadata["status"]
  end

  test "apply_corrected_xml returns false and changes nothing when corrected_xml is missing" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    original_content = message_draft.form_object.content
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => { "diff_errors" => ["FS zmenil IČO"], "corrected_xml" => nil }
    ))

    assert_no_enqueued_jobs only: Fs::ValidateMessageDraftJob do
      assert_not message_draft.apply_corrected_xml
    end

    message_draft.reload
    assert_equal original_content, message_draft.form_object.content
    assert_equal "invalid", message_draft.metadata["status"]
  end

  test "apply_corrected_xml refuses to overwrite a signed form and changes nothing" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.form_object.update!(is_signed: true)
    original_content = message_draft.form_object.content
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => { "diff_errors" => ["FS zmenil IČO"], "corrected_xml" => "<CorrectedForm>fixed</CorrectedForm>" }
    ))

    assert_not message_draft.correctable_xml?

    assert_no_enqueued_jobs only: Fs::ValidateMessageDraftJob do
      assert_not message_draft.apply_corrected_xml
    end

    message_draft.reload
    assert_equal original_content, message_draft.form_object.content
    assert_equal "invalid", message_draft.metadata["status"]
  end

  test "correctable_xml? is true only when a corrected_xml exists and the form is unsigned" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)

    message_draft.metadata["validation_errors"] = { "corrected_xml" => "<xml/>" }
    assert message_draft.correctable_xml?

    message_draft.metadata["validation_errors"] = { "corrected_xml" => nil }
    assert_not message_draft.correctable_xml?
  end

  test "correctable_xml? is false while a new validation is already running" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.metadata["validation_errors"] = { "corrected_xml" => "<xml/>" }

    message_draft.metadata["status"] = "being_validated"
    assert_not message_draft.correctable_xml?

    message_draft.metadata["status"] = "being_submitted"
    assert_not message_draft.correctable_xml?

    message_draft.metadata["status"] = "invalid"
    assert message_draft.correctable_xml?
  end

  test "diff_error_descriptions maps identifier field change to friendly label" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => ["3c3\n<       <ico>12345678</ico>\n---\n>       <ico>87654321</ico>"] }

    assert_equal ["IČO: pôvodne 12345678 → opravené 87654321"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions handles namespaced elements" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => ["1c1\n< <ns0:dic>1020304050</ns0:dic>\n---\n> <ns0:dic>9999999999</ns0:dic>"] }

    assert_equal ["DIČ: pôvodne 1020304050 → opravené 9999999999"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions falls back to raw element name for unknown fields" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => ["1c1\n< <nejakePole>a</nejakePole>\n---\n> <nejakePole>b</nejakePole>"] }

    assert_equal ["nejakePole: pôvodne a → opravené b"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions reports multiple changes" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => [
      "3c3\n<   <ico>11111111</ico>\n---\n>   <ico>22222222</ico>\n7c7\n<   <psc>81101</psc>\n---\n>   <psc>81102</psc>"
    ] }

    assert_equal ["IČO: pôvodne 11111111 → opravené 22222222", "PSČ: pôvodne 81101 → opravené 81102"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions keeps changes paired when an added-only hunk sits between them" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => [
      "29c29\n<   <datumZaplatenia>15.3.2025</datumZaplatenia>\n---\n>   <datumZaplatenia>15.03.2025</datumZaplatenia>\n" \
      "34a35\n>     <riadok/>\n" \
      "58c59\n<   <podpis>0</podpis>\n---\n>   <podpis>1</podpis>"
    ] }

    assert_equal ["datumZaplatenia: pôvodne 15.3.2025 → opravené 15.03.2025", "podpis: pôvodne 0 → opravené 1"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions reports a value the form cleared" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => [
      "39c39\n<       <mesiac>04</mesiac>\n---\n>       <mesiac>4</mesiac>\n" \
      "46c46\n<         <kodStatu>cz</kodStatu>\n---\n>         <kodStatu/>"
    ] }

    assert_equal ["mesiac: pôvodne 04 → opravené 4", "kodStatu: pôvodne cz → opravené (prázdne)"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions reports a value the form filled in" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => ["12c12\n<     <zaRok/>\n---\n>     <zaRok>2025</zaRok>"] }

    assert_equal ["zaRok: pôvodne (prázdne) → opravené 2025"], message_draft.diff_error_descriptions
  end

  test "diff_error_descriptions returns generic description when diff is unparseable" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.metadata["validation_errors"] = { "diff_errors" => [
      "garbage without diff markers",
      "5a6,7\n>       <novaSekcia>\n>       </novaSekcia>",
      "1c1\n< <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n---\n> <?xml version=\"1.0\" encoding=\"utf-8\"?>"
    ] }

    assert_equal ["Niektoré údaje sa zmenili, pred odoslaním ich skontrolujte vo formulári."] * 3, message_draft.diff_error_descriptions
  end

  test "validate_and_process marks message as invalid if there are validation errors" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    message_draft.validate_and_process

    assert_equal 'invalid', message_draft.metadata['status']
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_error_tag)
    assert message_draft.thread.tags.include?(message_draft.tenant.problem_tag)
    assert_includes message_draft.metadata['validation_errors']['internal_errors'], "Chýba požadovaná príloha pre UVPOD3_UA (minimum je 1)."
  end

  test "validate_and_process unassigns signature requested tags if there are validation errors" do
    message_draft = messages(:fs_accountants_draft_uzmujv14)
    signature_requested_tag = tags(:accountants_signers_signature_requested)
    message_draft.thread.assign_tag(signature_requested_tag)
    message_draft.form_object.assign_tag(signature_requested_tag)
    message_draft.validate_and_process

    assert_not message_draft.thread.tags.include?(signature_requested_tag)
    assert_not message_draft.form_object.tags.include?(signature_requested_tag)
  end

  test "validate_and_process sets status to created if no errors or warnings" do
    message_draft = messages(:fs_accountants_outbox)
    message_draft.validate_and_process

    assert_equal 'created', message_draft.metadata['status']
    assert_not message_draft.metadata['validation_errors']['internal_errors'].any?
  end

  test "validate_and_process removes problem and validation error tags if no errors or warnings" do
    message_draft = messages(:fs_accountants_outbox)
    message_draft.thread.assign_tag(message_draft.tenant.problem_tag)
    message_draft.validate_and_process

    assert_not message_draft.thread.tags.include?(message_draft.tenant.validation_error_tag)
    assert_not message_draft.thread.tags.include?(message_draft.tenant.problem_tag)
  end

  test "validate_and_process adds problem and validation warning tags if warnings exist" do
    message_draft = messages(:fs_accountants_outbox)
    message_draft.metadata['validation_errors']['warnings'] << "A warning"
    message_draft.validate_and_process

    assert_equal 'created', message_draft.metadata['status']
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_warning_tag)
    assert message_draft.thread.tags.include?(message_draft.tenant.problem_tag)
  end

  test "validate_and_process requests signature if required and not signed" do
    message_draft = messages(:fs_accountants_outbox)
    message_draft.validate_and_process

    assert_equal 'created', message_draft.metadata['status']
    assert message_draft.form_object.tags.any? { |tag| tag.type == 'SignatureRequestedFromTag' }
    assert message_draft.thread.tags.any? { |tag| tag.type == 'SignatureRequestedFromTag' }
  end

  test "signable_by_author? returns false if author is not a signer" do
    author = users(:basic)
    author.group_memberships.where(group: author.tenant.signer_group).destroy_all

    box = boxes(:fs_accountants)
    box.api_connections.destroy_all
    box.api_connections << api_connections(:fs_api_connection1).tap { |c| c.update(owner: nil) }

    message_draft = Fs::MessageDraft.new(author: author, thread: MessageThread.new(box: box))

    assert_not message_draft.signable_by_author?
  end

  test "signable_by_author? returns true if single global api connection without owner exists" do
    author = users(:accountants_basic)
    author.groups << author.tenant.signer_group

    box = boxes(:fs_accountants)
    box.api_connections.destroy_all

    box.api_connections << api_connections(:fs_api_connection1).tap { |c| c.update(owner: nil) }

    message_draft = Fs::MessageDraft.new(author: author, thread: MessageThread.new(box: box))

    assert message_draft.signable_by_author?
  end

  test "signable_by_author? returns true if author owns an api connection for the box" do
    author = users(:accountants_basic)
    author.groups << author.tenant.signer_group

    box = boxes(:fs_accountants)
    box.api_connections.destroy_all

    box.api_connections << api_connections(:fs_api_connection1).tap { |c| c.update(owner: author) }

    message_draft = Fs::MessageDraft.new(author: author, thread: MessageThread.new(box: box))

    assert message_draft.signable_by_author?
  end

  test "signable_by_author? returns false if only colleagues own api connections" do
    author = users(:accountants_basic)
    colleague = users(:accountants_user2)
    author.groups << author.tenant.signer_group

    box = boxes(:fs_accountants)
    box.api_connections.destroy_all

    box.api_connections << api_connections(:fs_api_connection1).tap { |c| c.update(owner: colleague) }

    message_draft = Fs::MessageDraft.new(author: author, thread: MessageThread.new(box: box))

    assert_not message_draft.signable_by_author?
  end

  test "signable_by_author? returns true if author owns one of multiple connections on the box" do
    author = users(:accountants_basic)
    colleague = users(:accountants_user2)
    author.groups << author.tenant.signer_group

    box = boxes(:fs_accountants)
    box.api_connections.destroy_all

    box.api_connections << api_connections(:fs_api_connection1).tap { |c| c.update(owner: colleague) }
    box.api_connections << api_connections(:fs_api_connection2).tap { |c| c.update(owner: author) }

    message_draft = Fs::MessageDraft.new(author: author, thread: MessageThread.new(box: box))

    assert message_draft.signable_by_author?
  end

  test "submittable? returns false for inactive box" do
    message_draft = messages(:fs_accountants_draft)
    message_draft.metadata["status"] = "created"
    message_draft.box.update!(active: false)

    message_draft.define_singleton_method(:form_object) { Struct.new(:content).new("payload") }

    message_draft.stub :any_objects_with_requested_signature?, false do
      message_draft.stub :valid?, true do
        assert_not message_draft.submittable?
      end
    end
  end
end
