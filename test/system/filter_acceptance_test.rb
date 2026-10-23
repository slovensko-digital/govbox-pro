require "application_system_test_case"

class FilterAcceptanceTest < ApplicationSystemTestCase
  setup do
    @tenant = tenants(:ssd)
    @tenant.enable_feature(:personalized_filters, force: true)
    @user = users(:basic)
    @other = users(:basic_two)
    @user.set_filter_visibility!(filters(:one).id, visible: true)
    @all = Filter.create!(tenant: @tenant, common: true, name: "All messages", query: "")
    @hidden = Filter.create!(tenant: @tenant, author: @user, name: "My hidden", query: "acceptance-hidden")
    @user.set_filter_visibility!(@hidden.id, visible: false)
    Searchable::MessageThread.reindex_all
    sign_in_as(:admin)
  end

  test "administrator and two users retain independent menus through the filter lifecycle" do
    publish_common("Team general", "general")
    publish_common("Team hidden", "acceptance-hidden")
    common = @tenant.filters.common.find_by!(query: "general")
    common_hidden = @tenant.filters.common.find_by!(query: "acceptance-hidden")
    assert_not @user.user_filter_visibilities.find_by!(filter: common).visible?
    assert_not @user.user_filter_visibilities.find_by!(filter: common_hidden).visible?
    subscription = FilterSubscription.create!(tenant: @tenant, user: @user, filter: common,
      events: ["Notifications::NewMessageThread"])
    other_subscription = FilterSubscription.create!(tenant: @tenant, user: @other, filter: common,
      events: ["Notifications::NewMessageThread"])

    sign_out
    sign_in_as(:basic)
    within_sidebar do
      assert_link "With General text"
      assert_no_link "Team general"
      assert_no_link "Team hidden"
      assert_no_link "My hidden"
    end
    click_link "Zrušiť vyhľadávanie"
    assert_current_path message_threads_path(q: "")
    assert_field "search", with: ""
    visit filters_path
    within("[data-filter-id='#{filters(:one).id}']") { click_button "Odopnúť" }
    within("[data-filter-id='#{filters(:one).id}']") do
      assert_button "Pripnúť"
      assert_text "Notifikácie zapnuté"
    end
    visit message_threads_path(q: common.query)
    within("#bulk_actions") do
      assert_text "With General text"
      click_link "Nastaviť notifikácie"
    end
    check "Nová správa"
    click_button "Nastaviť notifikácie"
    assert_no_selector "turbo-frame#modal form"
    assert_equal common.id, subscription.reload.filter_id
    assert_includes subscription.events, "Notifications::NewMessage"

    assert_difference -> { @user.notifications.count }, 1 do
      NotifyFilterSubscriptionJob.perform_now(subscription, message_threads(:ssd_main_general), false)
    end
    assert_no_difference -> { @other.notifications.count } do
      NotifyFilterSubscriptionJob.perform_now(other_subscription, message_threads(:ssd_main_general), false)
    end
    visit notifications_path
    click_link "Team general"
    assert_current_path message_threads_path(q: "general")
    within("#bulk_actions") { assert_text "With General text" }
    assert_not @user.user_filter_visibilities.find_by!(filter: filters(:one)).visible?
    capture_demo("personal-filter-notification-context.png")

    original_all_position = @user.user_filter_visibilities.find_by!(filter: @all).position
    visit new_filter_path
    fill_in "Názov filtra", with: "My all"
    fill_in "Dopyt na vyhľadávanie", with: ""
    click_button "Vytvoriť"
    assert_current_path filters_path
    personal_all = @user.filters.find_by!(name: "My all")
    visit root_path
    within("#bulk_actions") { assert_text "My all" }
    visit filters_path
    accept_confirm do
      within("[data-filter-id='#{personal_all.id}']") { click_link "Zmazať filter" }
    end
    assert_no_selector "[data-filter-id='#{personal_all.id}']"
    assert_equal @all, @user.pinned_filters.first
    assert_equal original_all_position, @user.user_filter_visibilities.find_by!(filter: @all).position
    basic_preferences = @user.user_filter_visibilities.order(:id).map(&:attributes)

    sign_out
    sign_in_as(:basic_two)
    visit filters_path
    within("[data-filter-id='#{common.id}']") { find("button[aria-label='Posunúť vyššie: Team general']").send_keys(:enter) }
    assert_selector "[data-filter-id='#{common.id}']:first-child"
    visit root_path
    within("#bulk_actions") { assert_text "Team general" }
    assert_equal basic_preferences, @user.user_filter_visibilities.order(:id).map(&:attributes)
    capture_demo("independent-common-filter-default.png")

    sign_out
    sign_in_as(:admin)
    before_subscription = subscription.reload.attributes
    visit edit_filter_path(common)
    fill_in "Dopyt na vyhľadávanie", with: "acceptance-edited"
    click_button "Uložiť"
    assert_text "Meníte podmienky spoločného filtra"
    click_button "Potvrdiť zmenu dopytu"
    assert_current_path filters_path
    assert_equal "acceptance-edited", common.reload.query
    assert_equal before_subscription, subscription.reload.attributes

    visit confirm_destroy_filter_path(common)
    assert_text "Počet používateľov s odberom: 2"
    capture_demo("common-filter-two-subscribers.png")
    click_link "Zrušiť"
    assert_current_path filters_path
    assert FilterSubscription.exists?(subscription.id)
    visit confirm_destroy_filter_path(common)
    click_button "Odstrániť filter"
    assert_current_path filters_path
    assert_no_selector "[data-filter-id='#{common.id}']"
    assert_not FilterSubscription.exists?(subscription.id)
    assert_not FilterSubscription.exists?(other_subscription.id)
    assert_equal @all, @other.pinned_filters.first
    assert Filter.exists?(filters(:one).id)
    assert Filter.exists?(@hidden.id)
    assert MessageThread.exists?(message_threads(:ssd_main_general).id)
  end

  private

  def publish_common(name, query)
    visit new_filter_path
    fill_in "Názov filtra", with: name
    fill_in "Dopyt na vyhľadávanie", with: query
    check "Spoločný filter pre všetkých"
    click_button "Vytvoriť"
    assert_current_path filters_path
    assert_text name
  end

  def capture_demo(name)
    page.save_screenshot(File.join(ENV["FILTER_DEMO_DIRECTORY"], name)) if ENV["FILTER_DEMO_DIRECTORY"]
  end
end
