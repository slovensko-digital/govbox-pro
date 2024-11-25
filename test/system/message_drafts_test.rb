require "application_system_test_case"

class MessageDraftsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    silence_warnings do
      @old_value = MessageThreadCollection.const_get("PER_PAGE")
      MessageThreadCollection.const_set("PER_PAGE", 1)
    end

    sign_in_as(:basic)
  end

  teardown do
    silence_warnings do
      MessageThreadCollection.const_set("PER_PAGE", @old_value)
    end
  end

  test "user can create message draft as reply on replyable message" do
    skip
  end

  test "templated message draft content is searchable" do
    message = messages(:ssd_main_empty_draft)
    thread = message_threads(:ssd_main_empty_draft)

    visit message_thread_path thread

    within "#body_upvs_message_draft_#{message.id}_form" do
      fill_in "message_draft_Text", with: "Pozdrav zo Slovensko.Digital! :)"
      fill_in "message_draft_Predmet", with: "Pozdravovacia sprava"
    end

    assert_text "Zmeny boli uložené"

    GoodJob.perform_inline

    # Search the draft content keywords
    visit message_threads_path

    assert_no_selector "#next_page_area"

    fill_in "search", with: "Slovensko.Digital"
    find("#search").send_keys(:enter)

    assert_no_selector "#next_page_area"

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within_thread_in_listing(thread) do
      assert_text "Slovensko.Digital"
    end

    refute_selector(thread_in_listing_selector(thread_general))
    refute_selector(thread_in_listing_selector(thread_issue))
  end

  test "message is not submitted and flash message is shown when user tries to send message without requested signatures present" do
    message_thread = message_threads(:ssd_main_draft_to_be_signed2)
    message_draft = messages(:ssd_main_draft_to_be_signed2_draft)

    visit message_thread_path(message_thread)

    within("#upvs_message_draft_#{message_draft.id}") do
      assert_button "Odoslať"

      click_button "Odoslať"
    end

    assert_text "Pred odoslaním podpíšte všetky dokumenty na podpis"
  end
end
