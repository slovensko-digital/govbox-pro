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

  test "group-wide permissions appear together below the group title" do
    get :edit_permissions, params: { tenant_id: @tenant.id, id: @group.id }

    assert_response :success
    assert_select "header #group-permissions" do
      assert_select "button[role=switch]", count: 2 do |switches|
        assert_equal ["Prístup ku všetkým schránkam", "Môže meniť prístup cez štítky"], switches.map { |switch| switch.text.strip }
      end
      assert_select "input[type=hidden][name=all_boxes_permission][value=true]"
      assert_select "input[type=hidden][name=can_manage_access_tags][value=true]"
    end
    assert_select "#boxes-column button[role=switch], #tags-column button[role=switch]", count: 0
  end

  test "admin group shows an enabled but disabled access tag permission switch" do
    get :edit_permissions, params: { tenant_id: @tenant.id, id: groups(:ssd_admins).id }

    assert_response :success
    assert_select "#group-permissions", text: /Môže meniť prístup cez štítky\s+Vždy povolené/
    assert_select "#group-permissions button[role=switch][aria-checked=true][disabled]", text: "Môže meniť prístup cez štítky", count: 1
    assert_select "input[name=can_manage_access_tags]", count: 0
  end

  test "admin cannot disable the admin group's permission" do
    group = groups(:ssd_admins)

    patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: group.id, can_manage_access_tags: "false" }

    assert_redirected_to root_path
    assert_equal "Prístup bol zamietnutý", flash[:alert]
    assert group.reload.can_manage_access_tags
  end

  test "blank access tag permission fails validation without updating the group" do
    [nil, ""].each do |value|
      patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: @group.id, can_manage_access_tags: value }

      assert_response :unprocessable_content
      refute @group.reload.can_manage_access_tags
      assert_nil flash[:notice]
    end
  end

  %i[ssd_all ssd_signers ssd_basic_user].each do |fixture|
    test "admin can revoke access tag management for #{fixture}" do
      group = groups(fixture)
      group.update!(can_manage_access_tags: true)

      get :edit_permissions, params: { tenant_id: @tenant.id, id: group.id }
      assert_response :success
      assert_select "input[name=can_manage_access_tags][value=false]"

      patch :update_can_manage_access_tags, params: { tenant_id: @tenant.id, id: group.id, can_manage_access_tags: "false" }

      assert_redirected_to edit_permissions_admin_tenant_group_url(@tenant, group)
      refute group.reload.can_manage_access_tags
    end
  end
end
