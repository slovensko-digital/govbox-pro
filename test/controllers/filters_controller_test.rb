require "test_helper"

class FiltersControllerTest < ActionController::TestCase
  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:basic).id
    session[:login_expires_at] = 1.day.from_now
  end

  teardown { Current.reset }

  test "owner can edit a personal definition without a pin" do
    patch :update, params: { id: filters(:one).id, filter: { name: "Changed" } }
    assert_redirected_to filters_path
    assert_equal "Changed", filters(:one).reload.name
  end

  test "saving an existing personal query returns it rather than duplicating it" do
    assert_no_difference "Filter.count" do
      post :create, params: { filter: { name: "Duplicate", query: " general " }, to: "search" }
    end
    assert_redirected_to message_threads_path(q: "general")
    assert_equal "With General text", filters(:one).reload.name
  end

  test "other users and tenants cannot mutate definitions by ID" do
    [filters(:two), filters(:solver_one)].each do |filter|
      before = filter.name
      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { id: filter.id, filter: { name: "Forbidden" } }
      end
      assert_equal before, filter.reload.name
    end
  end

  test "non-admin original author cannot edit a common definition" do
    filters(:one).update!(common: true)
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { id: filters(:one).id, filter: { name: "Forbidden" } }
    end
    assert_equal "With General text", filters(:one).reload.name
  end

  test "personalized menu GET does not create or rewrite preferences" do
    tenants(:ssd).enable_feature(:personalized_filters, force: true)
    3.times { |i| Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Menu #{i}", query: "menu-read-#{i}") }
    before = UserFilterVisibility.order(:id).map(&:attributes)
    get :index
    assert_response :success
    assert_equal before, UserFilterVisibility.order(:id).map(&:attributes)
  end

  test "non-administrator cannot publish a common filter with a forged flag" do
    assert_no_difference "Filter.count" do
      post :create, params: { filter: { name: "Forbidden common", query: "forbidden-common", common: true } }
    end
    assert_redirected_to root_path
  end

  test "administrator can publish without changing a personal duplicate" do
    session[:user_id] = users(:admin).id
    personal = filters(:one)
    before = personal.attributes
    post :create, params: { filter: { name: "Shared general", query: personal.query, common: true } }
    assert_redirected_to filters_path
    common = tenants(:ssd).filters.common.find_by!(query: personal.query)
    assert_equal before, personal.reload.attributes
    assert_not users(:basic).user_filter_visibilities.find_by!(filter: common).visible?
    assert_includes users(:basic_two).pinned_filters, common
    assert_equal personal, Filter.for_query(users(:basic), personal.query)
  end
end
