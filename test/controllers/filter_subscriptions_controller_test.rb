require "test_helper"

class FilterSubscriptionsControllerTest < ActionController::TestCase
  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:basic).id
    session[:login_expires_at] = 1.day.from_now
  end

  teardown { Current.reset }

  test "personal query view reuses the existing common subscription" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Common", query: "subscription-match")
    existing = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessage"])
    checkpoint = existing.reload.last_notify_run_at
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Personal", query: common.query)
    get :new, params: { filter_id: personal.id }
    assert_response :success
    assert_select "form[action='#{filter_filter_subscription_path(common, existing)}']"
    assert_no_difference "FilterSubscription.count" do
      post :create, params: { filter_id: personal.id, events: ["Notifications::NewMessageThread"] }
    end
    assert_equal common, @controller.view_assigns["filter"]
    assert_equal common.id, existing.reload.filter_id
    assert_equal checkpoint, existing.last_notify_run_at
    assert_equal ["Notifications::NewMessageThread"], existing.events
  end

  test "another user's personal and foreign tenant targets cannot be subscribed" do
    [filters(:two), filters(:solver_one)].each do |filter|
      assert_no_difference "FilterSubscription.count" do
        assert_raises(ActiveRecord::RecordNotFound) do
          post :create, params: { filter_id: filter.id, events: ["Notifications::NewMessage"] }
        end
      end
    end
  end

  test "subscription ownership and parent filter are both enforced" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Common", query: "secure-subscription")
    other = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:admin), filter: common, events: ["Notifications::NewMessage"])
    own = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessage"])
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { filter_id: common.id, id: other.id, events: [] }
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { filter_id: filters(:one).id, id: own.id, events: [] }
    end
    assert FilterSubscription.exists?(other.id)
    assert FilterSubscription.exists?(own.id)
  end
end
