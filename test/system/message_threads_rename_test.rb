require "application_system_test_case"

class MessageThreadsRenameTest < ApplicationSystemTestCase
  setup do
    @thread_general = message_threads(:ssd_main_general)

    sign_in_as(:basic)
  end

  test "user can rename thread" do
    visit message_thread_path(@thread_general)

    click_button "message-thread-options"
    click_link "Premenovať"

    fill_in "message_thread_title", with: "New name"

    click_button "Zmeniť názov"

    assert_text "New name"
  end
end
