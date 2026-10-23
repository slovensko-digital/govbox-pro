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
    visit settings_user_filter_visibilities_path
    within("[data-filter-id='#{common.id}']") do
      assert_selector "button[aria-label='Odopnúť z menu: Team invoices'][aria-pressed='true'][title='Pripnuté v menu'] svg.fill-current"
      find("button[aria-label='Odopnúť z menu: Team invoices']").send_keys(:enter)
    end
    visit filters_path
    within("[data-filter-id='#{common.id}']") do
      assert_text "Notifikácie zapnuté"
      assert_link "Nastaviť notifikácie"
    end
    visit settings_user_filter_visibilities_path
    within("[data-filter-id='#{common.id}']") do
      assert_selector "button[aria-label='Pripnúť do menu: Team invoices'][aria-pressed='false'][title='Nepripnuté v menu'] svg.fill-none"
      find("button[aria-label='Pripnúť do menu: Team invoices']").send_keys(:enter)
    end
    within("[data-filter-id='#{common.id}']") do
      find("button[aria-label='Posunúť vyššie v menu: Team invoices']").send_keys(:enter)
    end
    assert_selector "[data-filter-id='#{common.id}']:first-child"
    assert_equal common, users(:basic).pinned_filters.first
    assert_equal checkpoint, subscription.reload.last_notify_run_at
    visit root_path
    within("#bulk_actions") { assert_text "Team invoices" }
  end

  test "filter definitions and personal menu preferences have separate pages" do
    Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Unpinned example", query: "menu-separation")
    visit filters_path
    assert_text "Uložené vyhľadávania"
    assert_text "Moje menu"
    assert_no_selector "button[aria-label^='Pripnúť']"
    assert_no_selector "button[aria-label^='Odopnúť']"

    visit settings_user_filter_visibilities_path
    assert_text "Vyberte filtre, ktoré chcete mať v bočnom menu"
    assert_selector "[data-filter-id] button[aria-pressed]"
    assert_no_text "Nastaviť notifikácie"
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

  test "system tag shortcuts include visible system states and only the current user's signer tags" do
    user = users(:basic)
    system_query = "label:(#{tags(:ssd_drafts).name})"
    saved_system_filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Drafts shortcut", query: system_query)
    user.set_filter_visibility!(saved_system_filter.id, visible: true)
    group_signer_filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Group signer shortcut",
      query: "label:(#{tags(:ssd_signers_signature_requested).name})")
    user.set_filter_visibility!(group_signer_filter.id, visible: true)
    own_request = own_signed = nil
    assert_no_difference "Filter.count" do
      own_request = SignatureRequestedFromTag.create!(tenant: tenants(:ssd), owner: user, name: "Na podpis: My current user", visible: true)
      own_signed = SignedByTag.create!(tenant: tenants(:ssd), owner: user, name: "Podpísané: My current user", visible: true)
      SignatureRequestedFromTag.create!(tenant: tenants(:ssd), owner: users(:basic_two), name: "Na podpis: Other current user", visible: true)
      SignedByTag.create!(tenant: tenants(:ssd), owner: users(:basic_two), name: "Podpísané: Other current user", visible: true)
    end

    visit root_path
    within("[data-test='system-filters']") do
      assert_link tags(:ssd_drafts).name
      assert_link tags(:ssd_archived).name
      assert_link tags(:ssd_signature_requested).name
      assert_link tags(:ssd_signed).name
      assert_link own_request.name
      assert_link own_signed.name
      assert_no_link tags(:ssd_signer_user_signature_requested).name
      assert_no_link tags(:ssd_signer_user_signed).name
      assert_no_link tags(:ssd_signers_signature_requested).name
      assert_no_link group_signer_filter.name
    end
    expected_names = tenants(:ssd).tags.visible.where.not(type: SimpleTag.to_s)
      .where.not(type: [SignatureRequestedFromTag.to_s, SignedByTag.to_s]).pluck(:name)
    expected_names += tenants(:ssd).tags.visible.where(type: [SignatureRequestedFromTag.to_s, SignedByTag.to_s], owner: user).pluck(:name)
    assert_equal expected_names.sort, page.all("[data-test='system-filters'] a").map(&:text).sort
    assert_selector "a[href='#{message_threads_path(q: system_query)}']", count: 1
    assert_selector "a[href='#{message_threads_path(q: "label:(#{own_request.name})")}']"
    refute_includes page.all("[data-test='system-filters'] a").map(&:text), tags(:ssd_signer_user_signature_requested).name
  end
end
