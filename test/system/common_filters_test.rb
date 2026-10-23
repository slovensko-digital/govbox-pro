require "application_system_test_case"

class CommonFiltersTest < ApplicationSystemTestCase
  setup do
    tenants(:ssd).enable_feature(:personalized_filters, force: true)
    sign_in_as(:admin)
  end

  test "administrator publishes a shared definition without overwriting a personal match" do
    visit filters_path
    click_link "Vytvoriť filter"
    fill_in "Názov filtra", with: "Shared general"
    fill_in "Dopyt na vyhľadávanie", with: "general"
    check "Spoločný filter pre všetkých"
    click_button "Vytvoriť"
    assert_text "Shared general"
    common = tenants(:ssd).filters.common.find_by!(query: "general")
    assert_equal filters(:one), Filter.for_query(users(:basic), "general")
    assert_equal common, Filter.for_query(users(:basic_two), "general")
    assert_not users(:basic).user_filter_visibilities.find_by!(filter: common).visible?
  end

  test "administrator reviews and explicitly confirms a common query change" do
    filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Editable common", query: "edit-before")
    visit edit_filter_path(filter)
    fill_in "Dopyt na vyhľadávanie", with: "edit-after"
    click_button "Uložiť"
    assert_text "Meníte podmienky spoločného filtra"
    page.save_screenshot(File.join(ENV["FILTER_DEMO_DIRECTORY"], "common-filter-query-confirmation.png")) if ENV["FILTER_DEMO_DIRECTORY"]
    assert_equal "edit-before", filter.reload.query
    click_link "Zrušiť"
    assert_current_path filters_path
    assert_equal "edit-before", filter.reload.query
    visit edit_filter_path(filter)
    fill_in "Dopyt na vyhľadávanie", with: "edit-after"
    click_button "Uložiť"
    click_button "Potvrdiť zmenu dopytu"
    assert_current_path filters_path
    assert_equal "edit-after", filter.reload.query
  end

  test "administrator can cancel or confirm removal after seeing subscriber count" do
    filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Subscribed common", query: "delete-common")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: filter, events: ["Notifications::NewMessage"])
    visit filters_path
    within("[data-filter-id='#{filter.id}']") { click_link "Zmazať filter" }
    assert_text "Počet používateľov s odberom: 1"
    page.save_screenshot(File.join(ENV["FILTER_DEMO_DIRECTORY"], "common-filter-subscriber-warning.png")) if ENV["FILTER_DEMO_DIRECTORY"]
    click_link "Zrušiť"
    assert_current_path filters_path
    assert FilterSubscription.exists?(subscription.id)
    within("[data-filter-id='#{filter.id}']") { click_link "Zmazať filter" }
    assert_text "zrušia aj ich odbery notifikácií"
    click_button "Odstrániť filter"
    assert_current_path filters_path
    assert_no_selector "[data-filter-id='#{filter.id}']"
    assert_not Filter.exists?(filter.id)
    assert_not FilterSubscription.exists?(subscription.id)
  end
end
