require "application_system_test_case"

class AutomationTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)

    visit root_path
    click_link "Nastavenia"
    click_link "Pravidlá"
  end

  test "admin can create an automation rule" do
    click_link "Vytvoriť pravidlo"

    fill_in "Názov pravidla", with: "Test rule"
    click_button "Pokračovať"

    click_button "Pridať podmienku"
    assert_selector "#conditions turbo-frame"
    click_button "Pokračovať"

    click_button "Pridať akciu"
    assert_selector "button[title='Zmazať akciu']"
    click_button "Uložiť zmeny"

    assert_text "Nová správa, kde Schránka správy je"
    assert_text "Pridaj štítok na vlákno"
  end

  test "admin can edit an automation rule" do
    assert_no_text "Pridaj štítok na vlákno Construction" # TODO remove

    within("##{dom_id(automation_rules(:one))}") do
      click_link "Upraviť pravidlo"
    end

    fill_in "Názov pravidla", with: "Changed rule name"
    click_button "Pokračovať"

    within("##{dom_id(automation_conditions(:one))}") do
      click_button "Zmazať podmienku"
    end

    click_button "Pridať podmienku"
    click_button "Pokračovať"

    assert_selector "button[title='Zmazať akciu']"
    click_button "Zmazať akciu"
    assert_no_selector "button[title='Zmazať akciu']"
    click_button "Pridať akciu"
    assert_selector "button[title='Zmazať akciu']"
    click_button "Uložiť zmeny"

    # TODO assert_text "Changed rule name"
    within("##{dom_id(automation_rules(:one))}") do
      assert_text "Pridaj štítok na vlákno"
    end
  end

  test "admin can remove an automation rule" do
    assert_text "Pridaj štítok na vlákno Construction"

    within("##{dom_id(automation_rules(:two))}") do
      click_button "Zmazať pravidlo"
    end

    assert_no_text "Pridaj štítok na vlákno Construction"
  end
end
