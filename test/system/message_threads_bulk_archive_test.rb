require "application_system_test_case"

class MessageThreadsBulkArchiveTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)
  end

  test "user can archive multiple threads" do
    visit message_threads_path

    thread_issue = message_threads(:ssd_main_issue)
    thread_general = message_threads(:ssd_main_general)

    check "message_thread_#{thread_issue.id}"
    check "message_thread_#{thread_general.id}"

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    accept_alert do
      click_button "Archivovať"
    end

    assert_text "Vlákna boli zaradené na archiváciu"
  end

  test "user can unarchive multiple threads" do
    visit message_threads_path

    thread_issue = message_threads(:ssd_main_issue)
    thread_general = message_threads(:ssd_main_general)

    check "message_thread_#{thread_issue.id}"
    check "message_thread_#{thread_general.id}"

    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    accept_alert do
      click_button "Zrušiť archiváciu"
    end

    assert_text "Vláknam bola zrušená archivácia"
  end

end
