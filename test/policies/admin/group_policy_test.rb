require 'test_helper'

class Admin::GroupPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @user = users(:basic)
    @group = groups(:ssd_custom)
  end

  test 'update_can_manage_access_tags? returns true for an admin' do
    policy = Admin::GroupPolicy.new(@admin, @group)

    assert policy.update_can_manage_access_tags?
  end

  test 'update_can_manage_access_tags? returns false for a non-admin user' do
    policy = Admin::GroupPolicy.new(@user, @group)

    refute policy.update_can_manage_access_tags?
  end
end
