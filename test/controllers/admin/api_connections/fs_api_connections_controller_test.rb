require "test_helper"

class Admin::ApiConnections::FsApiConnectionsControllerTest < ActionController::TestCase
  setup do
    @controller = Admin::ApiConnections::FsApiConnectionsController.new
    @tenant = tenants(:accountants)
    @admin = users(:accountants_basic)
    @api_connection = api_connections(:fs_api_connection1)

    Current.tenant = @tenant
    Current.user = @admin
    session[:tenant_id] = @tenant.id
    session[:user_id] = @admin.id
    session[:login_expires_at] = Time.current + 1.day
  end

  teardown do
    Current.reset
  end

  test "init renders setup form" do
    get :init, params: { tenant_id: @tenant.id, id: @api_connection.id }

    assert_response :success
    assert_includes @response.body, "Konfigurácia prepojenia s FS"
    assert_not_includes @response.body, "Úprava prepojenia s FS"
    assert_not_includes @response.body, "Zahodiť"
    assert_includes @response.body, init_admin_tenant_api_connections_fs_api_connection_path(@tenant, @api_connection)
    assert_includes @response.body, "Prihlasovacie meno na portál FS"
    assert_includes @response.body, "Heslo na portál FS"
  end

  test "init save updates connection and boxifies" do
    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, []

    FsEnvironment.fs_client.stub :api, fs_api do
      patch :init, params: {
        tenant_id: @tenant.id,
        id: @api_connection.id,
        fs_api_connection: {
          custom_name: "Setup FS",
          settings_username: "new-login",
          settings_password: "new-password"
        }
      }
    end

    assert_redirected_to message_threads_path
    assert_equal "Prepojenie s FS bolo úspešne nastavené. Vytvorených schránok: 0", flash[:notice]

    @api_connection.reload
    assert_equal "Setup FS", @api_connection.custom_name
    assert_equal "new-login", @api_connection.settings_username
    assert_equal "new-password", @api_connection.settings_password
    fs_api.verify
  end

  test "init save does not boxify when update fails" do
    Fs::ApiConnection.class_eval do
      alias_method :update_without_test_failure, :update
      alias_method :boxify_without_test_failure, :boxify

      def update(*)
        false
      end

      def boxify
        raise "boxify must not be called"
      end
    end

    patch :init, params: {
      tenant_id: @tenant.id,
      id: @api_connection.id,
      fs_api_connection: {
        settings_username: "not-saved",
        settings_password: "not-saved"
      }
    }

    assert_response :unprocessable_content
  ensure
    Fs::ApiConnection.class_eval do
      alias_method :update, :update_without_test_failure
      alias_method :boxify, :boxify_without_test_failure
      remove_method :update_without_test_failure
      remove_method :boxify_without_test_failure
    end
  end

  test "init save keeps credentials and shows safe alert when boxify fails" do
    FsEnvironment.fs_client.stub :api, ->(*) { raise StandardError, "sensitive internal error" } do
      patch :init, params: {
        tenant_id: @tenant.id,
        id: @api_connection.id,
        fs_api_connection: {
          settings_username: "saved-login",
          settings_password: "saved-password"
        }
      }
    end

    assert_redirected_to init_admin_tenant_api_connections_fs_api_connection_path(@tenant, @api_connection)
    assert_includes flash[:alert], "Prepojenie bolo uložené"
    assert_not_includes flash[:alert], "sensitive internal error"

    @api_connection.reload
    assert_equal "saved-login", @api_connection.settings_username
    assert_equal "saved-password", @api_connection.settings_password
  end
end
