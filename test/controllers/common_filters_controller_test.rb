require "test_helper"

class CommonFiltersControllerTest < ActionController::TestCase
  tests FiltersController

  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:admin).id
    session[:login_expires_at] = 1.day.from_now
    @filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Shared query", query: "common-before")
    @subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: @filter, events: ["Notifications::NewMessage"])
  end

  teardown { Current.reset }

  test "query edit requires confirmation and preserves preferences and subscriptions" do
    before_preferences = UserFilterVisibility.where(filter: @filter).map(&:attributes)
    before_subscription = @subscription.reload.attributes
    patch :update, params: { id: @filter.id, filter: { query: "common-after" } }
    assert_response :unprocessable_content
    assert_equal "common-before", @filter.reload.query
    token = css_select('input[name="confirmation_token"]').first["value"]
    patch :update, params: { id: @filter.id, filter: { query: "common-after" }, confirmation_token: token }
    assert_redirected_to filters_path
    assert_equal "common-after", @filter.reload.query
    assert_equal before_preferences, UserFilterVisibility.where(filter: @filter).map(&:attributes)
    assert_equal before_subscription, @subscription.reload.attributes
  end

  test "stale or tampered query confirmation cannot authorize a different change" do
    token = @filter.query_change_confirmation(query: "common-after")
    @filter.update!(name: "Changed concurrently")
    patch :update, params: { id: @filter.id, filter: { query: "common-after" }, confirmation_token: token }
    assert_response :unprocessable_content
    assert_equal "common-before", @filter.reload.query
    token = @filter.query_change_confirmation(query: "common-after")
    patch :update, params: { id: @filter.id, filter: { query: "tampered" }, confirmation_token: token }
    assert_response :unprocessable_content
    assert_equal "common-before", @filter.reload.query
  end

  test "confirmed common edit permits a personal collision without changing delivery settings" do
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Personal", query: "personal-collision")
    token = @filter.query_change_confirmation(query: personal.query)
    patch :update, params: { id: @filter.id, filter: { query: personal.query }, confirmation_token: token }
    assert_redirected_to filters_path
    assert_equal personal, Filter.for_query(users(:basic), personal.query)
    assert_equal @filter.id, @subscription.reload.filter_id
  end

  test "deletion warns, preserves data until confirmed, and removes only the common source" do
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Personal", query: @filter.query)
    before = personal.attributes
    delete :destroy, params: { id: @filter.id }
    assert_response :unprocessable_content
    assert_select '[role="alert"]', text: /Počet používateľov s odberom: 1/
    assert Filter.exists?(@filter.id)
    assert FilterSubscription.exists?(@subscription.id)
    token = css_select('input[name="confirmation_token"]').first["value"]
    delete :destroy, params: { id: @filter.id, confirmation_token: token }
    assert_redirected_to filters_path
    assert_not Filter.exists?(@filter.id)
    assert_not FilterSubscription.exists?(@subscription.id)
    assert_empty UserFilterVisibility.where(filter_id: @filter.id)
    assert_equal before, personal.reload.attributes
    assert_empty personal.filter_subscriptions
  end

  test "changed subscribers require a fresh deletion confirmation" do
    token = @filter.deletion_confirmation
    FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic_two), filter: @filter, events: ["Notifications::NewMessage"])
    delete :destroy, params: { id: @filter.id, confirmation_token: token }
    assert_response :unprocessable_content
    assert_select '[role="alert"]', text: /Počet používateľov s odberom: 2/
    assert Filter.exists?(@filter.id)
  end

  test "removing first common pin falls back to next without deleting messages" do
    next_filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Next", query: "common-next")
    users(:basic_two).set_filter_visibility!(@filter.id, visible: true)
    users(:basic_two).set_filter_visibility!(next_filter.id, visible: true)
    before_messages = Message.count
    assert_equal @filter, users(:basic_two).pinned_filters.first
    delete :destroy, params: { id: @filter.id, confirmation_token: @filter.deletion_confirmation }
    assert_redirected_to filters_path
    assert_equal next_filter, users(:basic_two).pinned_filters.first
    assert_equal before_messages, Message.count
  end
end
