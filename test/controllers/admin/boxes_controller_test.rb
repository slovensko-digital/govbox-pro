require "test_helper"

class Admin::BoxesControllerTest < ActionController::TestCase
  setup do
    @controller = Admin::BoxesController.new
    @tenant = tenants(:accountants)
    @tenant.update!(feature_flags: (@tenant.feature_flags + ['fs_api']).uniq)
    @box = boxes(:fs_accountants)
    @box.update!(active: false)
    @admin = users(:accountants_basic)

    admin_group = @tenant.admin_group || Group.create!(name: "Admins", type: "AdminGroup", tenant: @tenant)
    @admin.groups << admin_group unless @admin.groups.include?(admin_group)

    Current.tenant = @tenant
    Current.user = @admin
    session[:tenant_id] = @tenant.id
    session[:user_id] = @admin.id
    session[:login_expires_at] = Time.now + 1.day
  end

  teardown do
    Current.reset
  end

  test "index renders inactive badge for inactive FS box" do
    get :index, params: { tenant_id: @tenant.id }

    assert_response :success
    assert_includes @response.body, "Neaktívna schránka"
    assert_includes @response.body, @box.name
  end
end
