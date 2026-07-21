require "application_system_test_case"

class Fs::MessageDraftXmlDiffTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:accountants_basic)
  end

  test "draft with diff_warnings shows yellow warning box and is submittable" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => ["FS upravil formátovanie: medzery normalizované"],
        "diff_errors"   => [],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      }
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/diff-warn-01-shows-yellow-box.png"

    within_message_in_thread(message_draft) do
      assert_text "Finančná správa upravila formátovanie správy"
      assert_no_text "Finančná správa upravila obsah správy"
      save_screenshot "tmp/diff-warn-02-within-message.png"
    end

    assert_no_text "Správa nie je validná"
  end

  test "draft with diff_warnings has validation_warning_tag and problem_tag on thread" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.metadata["validation_errors"] = {
      "result"        => "WARN",
      "errors"        => [],
      "warnings"      => [],
      "diff_warnings" => ["FS upravil formátovanie"],
      "diff_errors"   => [],
      "diff"          => [],
      "corrected_xml" => nil
    }
    message_draft.validate_and_process

    assert_equal "created", message_draft.metadata["status"]
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_warning_tag),
      "thread should carry validation_warning_tag when diff_warnings present"
    assert message_draft.thread.tags.include?(message_draft.tenant.problem_tag),
      "thread should carry problem_tag when diff_warnings present"
  end

  test "draft with diff_warnings shows apply correction button" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => ["Normalizácia medzier"],
        "diff_errors"   => [],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      }
    ))

    visit message_thread_path(message_draft.thread)

    within_message_in_thread(message_draft) do
      assert_button "Použiť opravu formátovania"
      save_screenshot "tmp/diff-warn-03-apply-button-visible.png"
    end
  end

  test "draft with diff_warnings but no corrected_xml does not show apply button" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => ["1c1\n< <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n---\n> <?xml version=\"1.0\" encoding=\"utf-8\"?>"],
        "diff_errors"   => [],
        "diff"          => [],
        "corrected_xml" => nil
      }
    ))

    visit message_thread_path(message_draft.thread)

    within_message_in_thread(message_draft) do
      assert_no_button "Použiť opravu formátovania"
      assert_text "Finančná správa upravila formátovanie správy"
      save_screenshot "tmp/diff-warn-04-no-apply-button-without-corrected-xml.png"
    end
  end

  test "draft with diff_errors shows red error box and is marked invalid" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"      => "WARN",
        "errors"      => [],
        "warnings"    => [],
        "diff_warnings" => [],
        "diff_errors" => ["FS zmenil IČO: 12345678 → 87654321"],
        "diff"        => [],
        "corrected_xml" => "<xml>corrected</xml>"
      },
      "status" => "invalid"
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/diff-error-01-shows-red-box.png"

    within_message_in_thread(message_draft) do
      assert_text "Finančná správa upravila obsah správy"
      assert_no_text "Finančná správa upravila formátovanie správy"
      save_screenshot "tmp/diff-error-02-within-message.png"
    end

    assert_text "Správa nie je validná"
  end

  test "validate_and_process with diff_errors marks draft invalid and assigns error tag" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.metadata["validation_errors"] = {
      "result"        => "WARN",
      "errors"        => [],
      "warnings"      => [],
      "diff_warnings" => [],
      "diff_errors"   => ["FS zmenil IČO"],
      "diff"          => [],
      "corrected_xml" => nil
    }
    message_draft.validate_and_process

    assert_equal "invalid", message_draft.metadata["status"]
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_error_tag),
      "thread should carry validation_error_tag when diff_errors present"
  end

  test "draft with diff_errors shows apply correction button" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["FS zmenil DIČ"],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      },
      "status" => "invalid"
    ))

    visit message_thread_path(message_draft.thread)

    within_message_in_thread(message_draft) do
      assert_button "Použiť opravu od Finančnej správy"
      save_screenshot "tmp/diff-error-03-apply-button-on-error.png"
    end
  end

  test "draft with a signed form does not offer to apply the corrected xml" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.form_object.update!(is_signed: true)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["FS zmenil IČO"],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      }
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/diff-error-04-signed-no-apply-button.png"

    within_message_in_thread(message_draft) do
      assert_text "Finančná správa upravila obsah správy"
      assert_no_button "Použiť opravu od Finančnej správy"
    end
  end

  test "applying corrected xml replaces blob, clears validation errors, and re-enqueues validation" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    original_blob = message_draft.form_object.content
    corrected_xml = "<CorrectedForm>new content</CorrectedForm>"

    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["FS zmenil IČO"],
        "diff"          => [],
        "corrected_xml" => corrected_xml
      },
      "status" => "invalid"
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/apply-correction-01-before.png"

    within_message_in_thread(message_draft) do
      assert_button "Použiť opravu od Finančnej správy"
    end

    accept_confirm do
      within_message_in_thread(message_draft) do
        click_button "Použiť opravu od Finančnej správy"
      end
    end

    save_screenshot "tmp/apply-correction-02-after-apply.png"

    assert_text "Prebieha validácia správy"

    message_draft.reload
    assert_equal corrected_xml, message_draft.form_object.content
    assert_equal({}, message_draft.metadata["validation_errors"])
    assert_not_equal original_blob, message_draft.form_object.content
  end

  test "apply button not shown when draft is already being validated" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "being_validated",
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["FS zmenil IČO"],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      }
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/apply-correction-03-being-validated-state.png"

    within_message_in_thread(message_draft) do
      assert_text "Prebieha validácia správy"
    end
  end

  test "validate_and_process with diff_errors in metadata always marks draft invalid" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["FS zmenil IČO"],
        "diff"          => [],
        "corrected_xml" => nil
      },
      "status" => "created"
    ))

    message_draft.validate_and_process

    assert_equal "invalid", message_draft.metadata["status"]
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_error_tag)
  end

  test "legacy diff level still treated as OK and not shown as error or warning" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"      => "OK",
        "errors"      => [],
        "warnings"    => [],
        "diff_warnings" => [],
        "diff_errors" => [],
        "diff"        => ["legacy diff message"],
        "corrected_xml" => nil
      }
    ))

    visit message_thread_path(message_draft.thread)
    save_screenshot "tmp/legacy-diff-01-no-warning-box.png"

    within_message_in_thread(message_draft) do
      assert_no_text "Finančná správa upravila obsah správy"
      assert_no_text "Finančná správa upravila formátovanie správy"
    end

    assert_no_text "Správa nie je validná"
  end

end
