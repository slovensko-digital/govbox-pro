require "application_system_test_case"

class GroupMembershipsTest < ApplicationSystemTestCase
  setup do
    @group_membership = group_memberships(:one)
  end

  test "visiting the index" do
    visit group_memberships_url
    assert_selector "h1", text: "Group memberships"
  end

  test "should create group membership" do
    visit group_memberships_url
    click_on "New group membership"

    fill_in "Group", with: @group_membership.group_id
    fill_in "User", with: @group_membership.user_id
    click_on "Create Group membership"

    assert_text "Group membership was successfully created"
    click_on "Back"
  end

  test "should update Group membership" do
    visit group_membership_url(@group_membership)
    click_on "Edit this group membership", match: :first

    fill_in "Group", with: @group_membership.group_id
    fill_in "User", with: @group_membership.user_id
    click_on "Update Group membership"

    assert_text "Group membership was successfully updated"
    click_on "Back"
  end

  test "should destroy Group membership" do
    visit group_membership_url(@group_membership)
    click_on "Destroy this group membership", match: :first

    assert_text "Group membership was successfully destroyed"
  end
end
