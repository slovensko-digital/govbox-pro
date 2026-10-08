require "test_helper"

class Admin::GroupsControllerTest < ActionController::TestCase
  tests Admin::GroupsController

  setup do
    @tenant = tenants(:ssd)
    @admin = users(:admin)
    @group = groups(:ssd_custom)

    Current.tenant = @tenant
    Current.user = @admin
    session[:tenant_id] = @tenant.id
    session[:user_id] = @admin.id
    session[:login_expires_at] = Time.now + 1.day
  end

  teardown do
    Current.reset
  end

  test "admin can enable the access tag management permission" do
    refute @group.can_manage_access_tags

    patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: @group.id, can_manage_access_tags: "true" }

    assert_redirected_to edit_permissions_admin_tenant_group_url(@tenant, @group)
    assert @group.reload.can_manage_access_tags
  end

  test "admin can disable the access tag management permission" do
    @group.update!(can_manage_access_tags: true)

    patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: @group.id, can_manage_access_tags: "false" }

    assert_redirected_to edit_permissions_admin_tenant_group_url(@tenant, @group)
    refute @group.reload.can_manage_access_tags
  end

  test "non-admin cannot change the access tag management permission" do
    user = users(:basic)
    Current.user = user
    session[:user_id] = user.id

    patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: @group.id, can_manage_access_tags: "true" }

    refute @group.reload.can_manage_access_tags
  end

  test "edit permissions renders the access tag management toggle" do
    get :edit_permissions, params: { tenant_id: @tenant.id, id: @group.id }

    assert_response :success
    assert_select "input[type=hidden][name=can_manage_access_tags][value=true]"
  end
end
