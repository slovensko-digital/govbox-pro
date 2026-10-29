require "test_helper"

class MessageThreadPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic)
    @thread = message_threads(:ssd_main_general)
    @finance = tags(:ssd_finance)
    @legal = tags(:ssd_legal)
    @legal.groups << groups(:ssd_custom)
    @thread.tags = [@finance, @legal]
  end

  test "a matching group and box access allow visibility through either access tag" do
    assert_includes visible_threads, @thread

    @thread.tags = [@legal]
    refute_includes visible_threads, @thread

    @user.groups << groups(:ssd_custom)
    assert_includes visible_threads, @thread
  end

  test "matching tag group cannot bypass missing box access" do
    BoxGroup.where(box_id: @thread.box_id, group_id: @user.group_ids).destroy_all

    refute_includes visible_threads, @thread
  end

  test "management permission grants neither matching tag membership nor box access" do
    groups(:ssd_basic_user).update!(can_manage_access_tags: true)
    assert @user.can_manage_access_tags?
    @thread.tags = [@legal]

    refute_includes visible_threads, @thread

    @thread.tags = [@finance]
    BoxGroup.where(box_id: @thread.box_id, group_id: @user.group_ids).destroy_all
    refute_includes visible_threads, @thread
  end

  private

  def visible_threads
    MessageThreadPolicy::Scope.new(@user, MessageThread).resolve
  end
end
