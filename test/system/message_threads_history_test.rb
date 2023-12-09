require "application_system_test_case"

class MessageThreadsHistoryTest < ApplicationSystemTestCase
  setup do
    @thread_general = message_threads(:ssd_main_general)

    sign_in_as(:basic)
  end

  test "a user visit thread history" do
    visit message_thread_path(@thread_general)

    click_button "message-thread-options"
    click_link "História komunikácie"

    assert_text "História komunikácie"
  end
end
