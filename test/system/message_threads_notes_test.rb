require "application_system_test_case"

class MessageThreadsNoteTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)
  end

  test "user can add a thread note" do
    visit message_thread_path(message_threads(:ssd_main_delivery))

    click_button "message-thread-options"

    click_link "Pridať poznámku"

    fill_in "message_thread_note_note", with: "A note"

    click_button "Uložiť"

    assert_text "A note"
  end

  test "user can update a thread note" do
    visit message_thread_path(message_threads(:ssd_main_general))

    click_button "message-thread-options"

    click_link "Upraviť poznámku"

    fill_in "message_thread_note_note", with: "Updated note"

    click_button "Uložiť"

    assert_text "Updated note"
  end
end
