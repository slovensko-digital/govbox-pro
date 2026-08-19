require "application_system_test_case"

class Fs::MessageDraftXmlDiffTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:accountants_basic)
  end

  test "diff_warnings are ignored completely and draft stays submittable" do
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

    within_message_in_thread(message_draft) do
      assert_no_text "Správa pravdepodobne obsahuje nesprávne údaje"
      assert_no_button "Použiť opravené hodnoty"
    end

    assert_no_text "Správa nie je validná"
  end

  test "diff_warnings do not assign validation_warning_tag or problem_tag" do
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
    assert_not message_draft.thread.tags.include?(message_draft.tenant.validation_warning_tag)
    assert_not message_draft.thread.tags.include?(message_draft.tenant.problem_tag)
  end

  test "draft with diff_errors shows error box and is marked invalid" do
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

    within_message_in_thread(message_draft) do
      assert_text "Správa pravdepodobne obsahuje nesprávne údaje"
      assert_text "Pri nahratí súboru do HTML formulára došlo k zmenám hodnôt vybraných atribútov"
    end

    assert_text "Správa nie je validná"
  end

  test "changed values are listed in an expandable section" do
    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "validation_errors" => {
        "result"        => "WARN",
        "errors"        => [],
        "warnings"      => [],
        "diff_warnings" => [],
        "diff_errors"   => ["3c3\n< <ico>12345678</ico>\n---\n> <ico>87654321</ico>"],
        "diff"          => [],
        "corrected_xml" => "<xml>corrected</xml>"
      },
      "status" => "invalid"
    ))

    visit message_thread_path(message_draft.thread)

    within_message_in_thread(message_draft) do
      assert_no_text "IČO: 12345678 → 87654321"

      find("summary", text: "Zobraziť zmenené údaje").click

      assert_text "IČO: 12345678 → 87654321"
    end
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
    assert message_draft.thread.tags.include?(message_draft.tenant.validation_error_tag)
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
      assert_button "Použiť opravené hodnoty"
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

    within_message_in_thread(message_draft) do
      assert_text "Správa pravdepodobne obsahuje nesprávne údaje"
      assert_no_button "Použiť opravené hodnoty"
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

    within_message_in_thread(message_draft) do
      assert_button "Použiť opravené hodnoty"
    end

    accept_confirm do
      within_message_in_thread(message_draft) do
        click_button "Použiť opravené hodnoty"
      end
    end

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

    within_message_in_thread(message_draft) do
      assert_text "Prebieha validácia správy"
      assert_no_button "Použiť opravené hodnoty"
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

    within_message_in_thread(message_draft) do
      assert_no_text "Správa pravdepodobne obsahuje nesprávne údaje"
      assert_no_button "Použiť opravené hodnoty"
    end

    assert_no_text "Správa nie je validná"
  end
end
