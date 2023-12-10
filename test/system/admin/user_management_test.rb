require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)
    visit root_path
    click_link "Nastavenia"
    click_link "Používatelia"
  end

  test "admin create a new user" do
    click_link "Vytvoriť používateľa"

    fill_in "user_name", with: "Dummy User"
    fill_in "user_email", with: "test@test.sk"
    click_button "Uložiť"

    assert_text "test@test.sk"
  end

  test "admin can edit user" do
    within("#user_#{users(:admin).id}") do
      click_link "Editovať používateľa"
    end

    fill_in "user_name", with: "Dummy User"
    fill_in "user_email", with: "test@test.sk"
    click_button "Uložiť"

    assert_text "test@test.sk"
  end

  test "admin can delete user" do
    assert_text "Another user"

    within("##{dom_id(users(:basic_two))}") do
       click_button "Vymazať používateľa"
     end

    assert_no_text "Another user"
  end
end
