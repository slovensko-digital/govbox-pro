require "application_system_test_case"

class MessageThreadsBulkMergeTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)
  end

  test "a user merge multiple threads" do
    visit message_threads_path

    thread_issue = message_threads(:ssd_main_issue)
    thread_general = message_threads(:ssd_main_general)

    check "message_thread_#{thread_issue.id}"
    check "message_thread_#{thread_general.id}"

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    accept_alert do
      click_button "Spojiť vlákna"
    end

    assert_text "Vlákna boli úspešne spojené"
  end
end
