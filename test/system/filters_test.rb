require "application_system_test_case"

class FiltersTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    sign_in_as(:ssd_signer)
  end

  test "user can create a filter" do
    visit message_threads_path(q: 'social')

    click_link "Pridať filter"

    fill_in "Názov", with: "My Filter"
    click_button "Vytvoriť"

    assert_text "My Filter"
    click_link "My Filter"

    assert_text "Social Department"
  end

  test "user can update a filter" do
    visit root_path
    click_link "Nastavenia"

    click_link "Upraviť filter"

    fill_in "filter_name", with: "Changed name"
    fill_in "filter_query", with: "New query"

    click_button "Uložiť"

    assert_text "Changed name"
  end

  test "user can delete a filter" do
    visit root_path
    click_link "Nastavenia"

    assert_text "General"

    accept_alert do
      click_button "Zmazať filter"
    end

    assert_no_text "General"
  end
end
