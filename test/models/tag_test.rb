require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:ssd)
    @user = users(:basic)
    @admin = users(:admin)

    @classification_tag = tags(:ssd_print)
    @access_tag = tags(:ssd_finance)
    # Fixtures insert tag_groups directly, bypassing the counter cache.
    Tag.reset_counters(@access_tag.id, :tag_groups)
    @access_tag.reload
  end

  test "gives_access? is true only for tags with tag groups" do
    assert @access_tag.gives_access?
    refute @classification_tag.gives_access?
  end

  test "classification tag is manageable by a regular user" do
    assert @classification_tag.manageable_by?(@user)
  end

  test "access tag is not manageable by a regular user" do
    refute @access_tag.manageable_by?(@user)
  end

  test "access tag is manageable by its owner" do
    owned_tag = @tenant.simple_tags.create!(name: "Owned access tag", owner: @user)
    owned_tag.groups << groups(:ssd_basic_user)
    owned_tag.reload

    assert owned_tag.gives_access?
    assert owned_tag.manageable_by?(@user)
  end

  test "manageable_by scope returns an owned access tag once even with several groups" do
    owned_tag = @tenant.simple_tags.create!(name: "Owned shared tag", owner: @user)
    owned_tag.groups << groups(:ssd_basic_user)
    owned_tag.groups << groups(:ssd_custom)
    owned_tag.reload

    scope = @tenant.simple_tags.visible.manageable_by(@user)

    assert owned_tag.gives_access?
    assert_equal [ owned_tag ], scope.where(id: owned_tag.id).to_a
  end

  test "access tag is manageable by a user whose group has the permission" do
    groups(:ssd_basic_user).update!(can_manage_access_tags: true)

    assert @access_tag.manageable_by?(@user)
  end

  test "access tag is manageable by an admin" do
    assert @access_tag.manageable_by?(@admin)
  end

  test "manageable_by scope returns every tag for an admin" do
    scope = @tenant.simple_tags.visible

    assert_equal scope.count, scope.manageable_by(@admin).count
  end

  test "manageable_by scope excludes access tags for a regular user" do
    scope = @tenant.simple_tags.visible.manageable_by(@user)

    assert_includes scope, @classification_tag
    refute_includes scope, @access_tag
  end

  test "manageable_by scope returns every tag for a user whose group has the permission" do
    groups(:ssd_basic_user).update!(can_manage_access_tags: true)
    scope = @tenant.simple_tags.visible

    assert_equal scope.count, scope.manageable_by(@user).count
  end
end
