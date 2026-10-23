require "application_system_test_case"

class PersonalizedFiltersTest < ApplicationSystemTestCase
  setup do
    tenants(:ssd).enable_feature(:personalized_filters, force: true)
    users(:basic).set_filter_visibility!(filters(:one).id, visible: true)
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)
  end

  test "complete query is displayed, refined, saved, and cleared without default reapplication" do
    assert_field "search", with: "general"
    query = "label:(NASES) faktúra"
    fill_in "search", with: query
    find("#search").send_keys(:enter)
    assert_current_path message_threads_path(q: query)
    click_link "Pridať filter"
    fill_in "Názov", with: "NASES invoices"
    click_button "Vytvoriť"
    assert_current_path message_threads_path(q: query)
    assert_field "search", with: query
    assert_equal query, users(:basic).filters.find_by!(name: "NASES invoices").query
    click_link "Zrušiť vyhľadávanie"
    assert_current_path message_threads_path(q: "")
    assert_field "search", with: ""
    assert_text "General agenda SSD"
  end

  test "unpinned subscribed filter remains manageable and can be reordered by keyboard" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Team invoices", query: "team-invoices")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessage"])
    checkpoint = subscription.reload.last_notify_run_at
    visit filters_path
    within("[data-filter-id='#{common.id}']") do
      find("button[aria-label='Odopnúť: Team invoices']").send_keys(:enter)
    end
    within("[data-filter-id='#{common.id}']") do
      assert_text "Notifikácie zapnuté"
      assert_link "Nastaviť notifikácie"
      find("button[aria-label='Pripnúť: Team invoices']").send_keys(:enter)
    end
    within("[data-filter-id='#{common.id}']") do
      find("button[aria-label='Posunúť vyššie: Team invoices']").send_keys(:enter)
    end
    assert_selector "[data-filter-id='#{common.id}']:first-child"
    assert_equal common, users(:basic).pinned_filters.first
    assert_equal checkpoint, subscription.reload.last_notify_run_at
    visit root_path
    within("#bulk_actions") { assert_text "Team invoices" }
  end

  test "personal query title retains controls for an existing common subscription" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Shared general", query: "personal-subs")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessage"])
    Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "My general", query: common.query)
    visit message_threads_path(q: common.query)
    within("#bulk_actions") do
      assert_text "My general"
      click_link "Nastaviť notifikácie"
    end
    assert_checked_field "Nová správa"
    check "Nová konverzácia"
    click_button "Nastaviť notifikácie"
    assert_no_selector "turbo-frame#modal form"
    assert_current_path message_threads_path(q: common.query)
    assert_equal common.id, subscription.reload.filter_id
    assert_includes subscription.events, "Notifications::NewMessageThread"
    assert_equal 1, FilterSubscription.for_query(users(:basic), common.query).count
  end

  test "notification opens current query of an unpinned source without repinning" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Notification source", query: "notification-old")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessageThread"])
    thread = message_threads(:ssd_main_general)
    users(:basic).notifications.create!(type: "Notifications::NewMessageThread", message_thread: thread,
      filter_subscription: subscription, filter_name: common.name)
    common.update!(query: "notification-current")
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "My notification query", query: common.query)
    users(:basic).set_filter_visibility!(common.id, visible: false)
    users(:basic).set_filter_visibility!(personal.id, visible: false)
    visit notifications_path
    assert_selector "a[href='#{message_thread_path(thread)}']"
    click_link "Notification source"
    assert_current_path message_threads_path(q: "notification-current")
    within("#bulk_actions") do
      assert_text "My notification query"
      assert_selector "a[href='#{edit_filter_filter_subscription_path(common, subscription)}']"
    end
    assert_not users(:basic).user_filter_visibilities.find_by!(filter: common).visible?
    assert_not users(:basic).user_filter_visibilities.find_by!(filter: personal).visible?
  end
end
