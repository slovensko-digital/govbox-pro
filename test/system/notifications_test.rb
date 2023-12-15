require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)
  end

  test "user can subscribe to a filter and show notifications" do
    visit message_threads_path

    click_link "With General text"

    click_link "Nastaviť notifikácie"

    check "Nová konverzácia"
    check "Nová správa"
    check "Zmena poznámky"

    click_button "Nastaviť notifikácie"
    assert_text "Notifikácie boli nastavené!"

    add_note_to_thread(message_threads(:ssd_main_general))

    GoodJob.perform_inline

    find("#user-menu-button").click
    click_link "Notifikácie"

    assert_text "Zmenená poznámka na vlákne"
  end

  def add_note_to_thread(thread, note: "A note")
    visit message_thread_path(thread)
    click_button "message-thread-options"
    click_link "Upraviť poznámku"
    fill_in "message_thread_note_note", with: note
    click_button "Uložiť"

    assert_text note
  end
end
