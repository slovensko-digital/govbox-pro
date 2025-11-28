require "test_helper"

class UserBoxPermissionTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:ssd)
    @user = users(:basic)
    @box1 = boxes(:ssd_main)
    @box2 = boxes(:ssd_other)

    BoxGroup.delete_all
    GroupMembership.where(user: @user).delete_all

    @group = @tenant.groups.create!(name: "Test Group", type: "CustomGroup")
    @user.group_memberships.create!(group: @group)
  end

  test "accessible_boxes returns only boxes assigned to user's groups" do
    @group.boxes << @box1

    assert_includes @user.accessible_boxes, @box1
    assert_not_includes @user.accessible_boxes, @box2
  end

  test "accessible_boxes returns multiple boxes from multiple groups" do
    @group2 = @tenant.groups.create!(name: "Test Group 2", type: "CustomGroup")
    @user.group_memberships.create!(group: @group2)

    @group.boxes << @box1
    @group2.boxes << @box2

    assert_includes @user.accessible_boxes, @box1
    assert_includes @user.accessible_boxes, @box2
  end

  test "accessible_boxes returns empty if no boxes assigned" do
    assert_empty @user.accessible_boxes
  end

  test "MessageThreadPolicy scope respects accessible_boxes" do
    @group.boxes << @box1

    thread1 = message_threads(:ssd_main_general)
    thread1.update!(box: @box1)

    thread2 = MessageThread.create!(
      box: @box2,
      title: "Thread in Box 2",
      original_title: "Thread in Box 2",
      delivered_at: Time.now,
      last_message_delivered_at: Time.now
    )

    tag = tags(:ssd_finance)
    @group.tags << tag

    thread1.tags << tag unless thread1.tags.include?(tag)
    thread2.tags << tag unless thread2.tags.include?(tag)

    scope = MessageThreadPolicy::Scope.new(@user, MessageThread.all).resolve

    assert_includes scope, thread1
    assert_not_includes scope, thread2
  end
end
