require "test_helper"

class Settings::UserFilterVisibilitiesControllerTest < ActionController::TestCase
  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:basic).id
    session[:login_expires_at] = 1.day.from_now
  end

  teardown { Current.reset }

  test "pin, unpin, and move own filters" do
    get :index
    assert_response :success
    assert_select "h1", text: "Moje menu"

    post :create, params: { user_filter_visibility: { filter_id: filters(:one).id, visible: true } }
    assert_redirected_to settings_user_filter_visibilities_path
    preference = users(:basic).user_filter_visibilities.find_by!(filter: filters(:one))
    patch :update, params: { id: preference.id, user_filter_visibility: { visible: false } }
    assert_not preference.reload.visible?
    patch :update, params: { id: preference.id, user_filter_visibility: { visible: true } }
    post :move_higher, params: { id: preference.id }
    assert_redirected_to settings_user_filter_visibilities_path
  end

  test "foreign target IDs and foreign preference IDs cannot be mutated" do
    [filters(:two), filters(:solver_one)].each do |filter|
      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { user_filter_visibility: { filter_id: filter.id, visible: true } }
      end
    end
    preference = users(:admin).set_filter_visibility!(filters(:two).id, visible: true)
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { id: preference.id, user_filter_visibility: { visible: false } }
    end
    assert preference.reload.visible?
  end
end
