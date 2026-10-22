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
end
