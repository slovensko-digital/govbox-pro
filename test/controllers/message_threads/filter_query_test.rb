require "test_helper"

class MessageThreads::FilterQueryTest < ActionController::TestCase
  tests MessageThreadsController

  setup do
    session[:tenant_id] = tenants(:ssd).id
    session[:user_id] = users(:basic).id
    session[:login_expires_at] = 1.day.from_now
    tenants(:ssd).enable_feature(:personalized_filters, force: true)
    users(:basic).set_filter_visibility!(filters(:one).id, visible: true)
  end

  teardown { Current.reset }

  test "entry executes first pin without redirecting" do
    query = capture_query { get :index }
    assert_response :success
    assert_equal "general", query
    assert_equal "general", @controller.view_assigns["next_page_params"][:q]
  end

  test "explicit query never inherits the first filter" do
    assert_equal "Legal", capture_query { get :index, params: { q: " Legal " } }
    assert_response :success
  end

  test "explicit empty query bypasses the default and survives scroll parameters" do
    assert_equal "", capture_query { get :index, params: { q: "" } }
    assert_equal "", @controller.view_assigns["next_page_params"][:q]
    assert_equal "", capture_query { get :scroll, params: { q: "", format: :turbo_stream } }
  end

  test "no pins falls back to all messages" do
    users(:basic).set_filter_visibility!(filters(:one).id, visible: false)
    assert_equal "", capture_query { get :index }
  end

  test "disabled rollout keeps the original entry view" do
    tenants(:ssd).disable_feature(:personalized_filters, force: true)
    assert_equal "", capture_query { get :index }
  end

  test "search preserves permissions, user-relative parsing and cursor" do
    session[:box_id] = boxes(:ssd_main).id
    cursor = { last_message_delivered_at: "1700000000000", message_thread_id: "123" }
    capture_query { get :scroll, params: { q: "author:me", cursor: cursor, format: :turbo_stream } }
    assert_equal boxes(:ssd_main), @loaded_arguments[:search_permissions][:box]
    assert_equal users(:basic).accessible_boxes.pluck(:id).sort, @loaded_arguments[:search_permissions][:accessible_box_ids].sort
    assert_equal users(:basic).author_tag.name, @loaded_arguments[:user_tag_name]
    assert_equal "123", @loaded_arguments[:cursor][:message_thread_id]
    assert_equal Time.at(1700000000), @loaded_arguments[:cursor][:last_message_delivered_at]
  end

  test "clearing bulk selection restores the query header and notification controls" do
    post :bulk_actions, params: { q: "general", format: :turbo_stream }
    assert_response :success
    assert_includes response.body, "With General text"
    assert_includes response.body, "Nastaviť notifikácie"
  end

  test "personal title exposes an existing common subscription including empty query" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Common all", query: "")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: common, events: ["Notifications::NewMessage"])
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "My all", query: "")
    capture_query { get :index, params: { q: "" } }
    assert_select "#bulk_actions", text: /My all/
    assert_select "a[href='#{edit_filter_filter_subscription_path(common, subscription)}']"
    assert_equal personal, @controller.view_assigns["filter"]
  end

  test "a removed common query remains an ordinary search without stale controls" do
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Removed common", query: "removed-common")
    common.destroy!
    assert_equal "removed-common", capture_query { get :index, params: { q: "removed-common" } }
    assert_nil @controller.view_assigns["filter"]
    assert_select "#bulk_actions a[title='Nastaviť notifikácie']", count: 0
    assert_select "#bulk_actions", text: /Hľadaný výraz/
  end

  private

  def capture_query
    query = nil
    loader = ->(**arguments) do
      @loaded_arguments = arguments
      query = arguments.fetch(:query)
      { records: [], next_cursor: nil, count_estimate: 0 }
    end
    MessageThreadCollection.stub(:all, loader) { yield }
    query
  end
end
