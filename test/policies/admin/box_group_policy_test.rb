require 'test_helper'

class Admin::BoxGroupPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant = tenants(:accountants)
    @other_tenant = tenants(:ssd)
    @admin = users(:accountants_basic)
    @other_admin = users(:admin)
    @box = boxes(:fs_accountants)
    @group = groups(:accountants_admins)
    @other_tenant_box = boxes(:ssd_main)
    @box_group = BoxGroup.new(box: @box, group: @group)
  end

  test 'create? returns true for admin of the same tenant' do
    policy = Admin::BoxGroupPolicy.new(@admin, @box_group)
    assert policy.create?
  end

  test 'create? returns false for admin of a different tenant' do
    policy = Admin::BoxGroupPolicy.new(@other_admin, @box_group)
    refute policy.create?
  end

  test 'create? returns false for non-admin user' do
    user = users(:accountants_user4)
    policy = Admin::BoxGroupPolicy.new(user, @box_group)
    refute policy.create?
  end

  test 'destroy? delegates to create?' do
    policy = Admin::BoxGroupPolicy.new(@admin, @box_group)
    assert_equal policy.create?, policy.destroy?
  end
end
