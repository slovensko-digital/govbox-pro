require "application_system_test_case"

class TagManagementTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)
    visit root_path
    click_link "Nastavenia"
    click_link "Štítky"
  end

  test "admin can create a new simple tag" do
    click_link "Vytvoriť štítok"

    fill_in "simple_tag_name", with: "Dummy tag"
    click_button "Vytvoriť"

    assert_text "Dummy tag"
  end

  test "admin can update a simple tag" do
    within("##{dom_id(tags(:ssd_finance))}") do
      click_link "Editovať štítok"
    end

    fill_in "simple_tag_name", with: "Dummy new name"
    click_button "Uložiť zmeny"

    assert_text "Dummy new name"
  end

  test "admin can delete a tag" do
    within("##{dom_id(tags(:ssd_finance))}") do
      accept_alert do
        click_button "Zmazať štítok"
      end
    end

    assert_no_text "Finance"
  end
end
