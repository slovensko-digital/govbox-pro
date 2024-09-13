require "application_system_test_case"

class MessageThreadsBulkSignTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    sign_in_as(:ssd_signer)
  end

  test "user can sign multiple message objects" do
    visit message_threads_path

    thread1 = message_threads(:ssd_main_draft_to_be_signed)
    thread2 = message_threads(:ssd_main_draft_to_be_signed2)

    check "message_thread_#{thread1.id}"
    check "message_thread_#{thread2.id}"

    within_thread_in_listing(thread1) do
      assert_text users(:ssd_signer).signature_requested_from_tag.name
    end

    within_thread_in_listing(thread2) do
      assert_text users(:ssd_signer).signature_requested_from_tag.name
    end

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    click_button "Podpísať"

    assert_text "Vybrané vlákna obsahujú 3 dokumenty na podpis."
  end

  test "user can not sign multiple message objects unless their SignatureRequestedFrom Tag is assigned" do
    sign_in_as(:ssd_signer2)

    visit message_threads_path

    thread1 = message_threads(:ssd_main_draft_to_be_signed)
    thread2 = message_threads(:ssd_main_draft_to_be_signed2)

    within_thread_in_listing(thread1) do
      assert_no_text users(:ssd_signer2).signature_requested_from_tag.name
    end

    within_thread_in_listing(thread2) do
      assert_no_text users(:ssd_signer2).signature_requested_from_tag.name
    end

    check "message_thread_#{thread1.id}"
    check "message_thread_#{thread2.id}"

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    click_button "Podpísať"

    assert_text "Vo vybraných vláknach sa nenašli žiadne dokumenty so žiadosťou na podpis"
  end

  test "user can sign multiple message objects with assigned SignatureRequestedFrom SignerGroup Tag" do
    visit message_threads_path

    thread1 = message_threads(:ssd_main_draft_to_be_signed3)
    thread2 = message_threads(:ssd_main_draft_to_be_signed4)

    within_thread_in_listing(thread1) do
      assert_text users(:ssd_signer).tenant.signer_group.signature_requested_from_tag.name
    end

    within_thread_in_listing(thread2) do
      assert_text users(:ssd_signer).tenant.signer_group.signature_requested_from_tag.name
    end

    check "message_thread_#{thread1.id}"
    check "message_thread_#{thread2.id}"

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    click_button "Podpísať"

    assert_text "Vybrané vlákna obsahujú 3 dokumenty na podpis."
  end
end
