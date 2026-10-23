require "test_helper"

class BoxesFilterContextTest < ActionController::TestCase
  tests BoxesController

  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:basic).id
    session[:login_expires_at] = 1.day.from_now
  end

  teardown { Current.reset }

  test "box selection preserves explicit empty or complete query referer" do
    ["", "label:(NASES) faktúra"].each do |query|
      url = message_threads_url(q: query)
      @request.env["HTTP_REFERER"] = url
      get :select, params: { id: boxes(:ssd_main).id }
      assert_redirected_to url
      assert_equal boxes(:ssd_main).id, session[:box_id]
      get :select_all
      assert_redirected_to url
      assert_nil session[:box_id]
    end
  end
end
