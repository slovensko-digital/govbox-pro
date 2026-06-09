require "test_helper"

class MessageThreads::FsApiConnectionSetupNoticeTest < ActionController::TestCase
  tests MessageThreadsController

  setup do
    @tenant = tenants(:accountants)
    @admin = users(:accountants_basic)

    Current.tenant = @tenant
    Current.user = @admin
    session[:tenant_id] = @tenant.id
    session[:user_id] = @admin.id
    session[:login_expires_at] = Time.current + 1.day
  end

  teardown do
    Current.reset
  end

  test "index shows setup notice for current tenant fs api connection missing username" do
    connection = Fs::ApiConnection.create!(
      tenant: @tenant,
      sub: "missing-username",
      api_token_private_key: api_connections(:fs_api_connection1).api_token_private_key,
      settings_password: "password"
    )

    get :index

    assert_response :success
    assert_includes @response.body, "Nastavte prepojenie s finančnou správou"
    assert_includes @response.body, init_admin_tenant_api_connections_fs_api_connection_path(@tenant, connection)
  end

  test "index shows setup notice for current tenant fs api connection missing password" do
    connection = Fs::ApiConnection.create!(
      tenant: @tenant,
      sub: "missing-password",
      api_token_private_key: api_connections(:fs_api_connection1).api_token_private_key,
      settings_username: "username"
    )

    get :index

    assert_response :success
    assert_includes @response.body, "Nastavte prepojenie s finančnou správou"
    assert_includes @response.body, init_admin_tenant_api_connections_fs_api_connection_path(@tenant, connection)
  end

  test "index does not show setup notice when current tenant fs credentials are configured" do
    @tenant.api_connections.where(type: "Fs::ApiConnection").each do |connection|
      connection.update!(settings_username: "username", settings_password: "password")
    end

    get :index

    assert_response :success
    assert_not_includes @response.body, "Nastavte prepojenie s finančnou správou"
  end

  test "index does not show setup notice for non-fs or other tenant missing credentials" do
    @tenant.api_connections.where(type: "Fs::ApiConnection").each do |connection|
      connection.update!(settings_username: "username", settings_password: "password")
    end

    Govbox::ApiConnectionWithOboSupport.create!(
      tenant: @tenant,
      sub: "govbox-missing-settings",
      api_token_private_key: "private_key"
    )

    other_connection = api_connections(:fs_api_connection2)
    other_connection.update!(settings_username: nil, settings_password: nil)

    get :index

    assert_response :success
    assert_not_includes @response.body, "Nastavte prepojenie s finančnou správou"
    assert_not_includes @response.body, init_admin_tenant_api_connections_fs_api_connection_path(other_connection.tenant, other_connection)
  end
end
