require "application_system_test_case"

class MessageThreadsBulkDestroyTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)
  end

  test "user can merge multiple threads" do
    visit message_threads_path

    thread_issue = message_threads(:ssd_main_issue)
    thread_general = message_threads(:ssd_main_general)
    thread_draft = message_threads(:ssd_main_draft_only)

    thread_issue_messages_count = thread_issue.messages.count
    thread_general_messages_count = thread_general.messages.count

    check "message_thread_#{thread_issue.id}"
    check "message_thread_#{thread_general.id}"
    check "message_thread_#{thread_draft.id}"

    assert_text "3 označené správy"

    click_button "Hromadné akcie"

    accept_alert do
      click_button "Zmazať rozpracované"
    end

    assert_text "Rozpracované správy vo vláknach boli zahodené"

    assert_equal thread_issue_messages_count, thread_issue.reload.messages.count
    assert_not_equal thread_general_messages_count, thread_general.reload.messages.count
    assert_not MessageThread.exists?(thread_draft.id)

    assert thread_issue.reload.message_drafts.count == 0
    assert thread_general.reload.message_drafts.count == 0
  end
end
