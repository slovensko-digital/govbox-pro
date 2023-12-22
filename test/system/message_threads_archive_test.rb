require "application_system_test_case"

class MessageThreadsArchiveTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:basic)
  end

  test "user can archive and unarchive a message thread" do
    visit message_thread_path(message_threads(:ssd_main_general))

    click_button "message-thread-options"
    click_button "Archivovať vlákno"

    assert_text "Archivácia vlákna bola úspešne upravená"
  end

  test "user can unarchive a message thread" do
    visit message_thread_path(message_threads(:ssd_main_issue))

    click_button "message-thread-options"
    click_link "Nearchivovať vlákno"

    assert_text "Vlákno je archivované"

    click_button "Zrušiť archiváciu vlákna"

    assert_text "Archivácia vlákna bola úspešne upravená"
  end
end
