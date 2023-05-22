require "test_helper"

class GroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_membership = group_memberships(:one)
  end

  test "should get index" do
    get group_memberships_url
    assert_response :success
  end

  test "should get new" do
    get new_group_membership_url
    assert_response :success
  end

  test "should create group_membership" do
    assert_difference("GroupMembership.count") do
      post group_memberships_url, params: { group_membership: { group_id: @group_membership.group_id, user_id: @group_membership.user_id } }
    end

    assert_redirected_to group_membership_url(GroupMembership.last)
  end

  test "should show group_membership" do
    get group_membership_url(@group_membership)
    assert_response :success
  end

  test "should get edit" do
    get edit_group_membership_url(@group_membership)
    assert_response :success
  end

  test "should update group_membership" do
    patch group_membership_url(@group_membership), params: { group_membership: { group_id: @group_membership.group_id, user_id: @group_membership.user_id } }
    assert_redirected_to group_membership_url(@group_membership)
  end

  test "should destroy group_membership" do
    assert_difference("GroupMembership.count", -1) do
      delete group_membership_url(@group_membership)
    end

    assert_redirected_to group_memberships_url
  end
end
