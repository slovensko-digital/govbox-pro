require "application_system_test_case"

class GroupManagementTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)
    visit root_path
    click_link "Nastavenia"
    click_link "Skupiny"
  end

  test "admin create a new group" do
    click_link "Vytvoriť skupinu"

    fill_in "custom_group_name", with: "Dummy Group"
    click_button "Vytvoriť"

    fill_in "name_search", with: "Basi"

    click_button "Pridať používateľa do skupiny"
    click_link "Zatvoriť"

    assert_text "Dummy Group"
  end

  test "admin can add user to group" do
    within("##{dom_id(groups(:ssd_signers))}") do
      click_link "Zmeniť členov skupiny"
    end

    fill_in "name_search", with: "Basi"

    click_button "Pridať používateľa do skupiny"
    assert_text "Basic"
    click_link "Zatvoriť"
  end

  test "admin can delete a group" do
    assert_text "Custom group"

    within("##{dom_id(groups(:ssd_custom))}") do
      accept_alert do
        click_button "Zmazať skupinu"
      end
    end

    assert_no_text "Custom group"
  end
end
