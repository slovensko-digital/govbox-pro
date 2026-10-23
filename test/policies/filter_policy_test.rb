require "test_helper"

class FilterPolicyTest < ActiveSupport::TestCase
  test "common definitions require an administrator even for the original author" do
    filter = filters(:one)
    filter.update!(common: true)
    assert_not FilterPolicy.new(users(:basic), filter).edit?
    assert FilterPolicy.new(users(:admin), filter).edit?
    assert_not FilterPolicy.new(users(:accountants_basic), filter).edit?
  end

  test "personal definitions are manageable only by their owner" do
    filter = filters(:one)
    assert FilterPolicy.new(users(:basic), filter).update?
    assert_not FilterPolicy.new(users(:basic_two), filter).destroy?
    assert_not FilterPolicy.new(users(:admin), filter).update?
    assert_includes FilterPolicy::ScopeEditable.new(users(:basic), Filter).resolve, filter
    assert_not_includes FilterPolicy::ScopeEditable.new(users(:admin), Filter).resolve, filter
  end

  test "showable scope includes common and own personal but not foreign filters" do
    filters(:two).update!(common: true)
    scope = FilterPolicy::ScopeShowable.new(users(:basic), Filter).resolve
    assert_includes scope, filters(:one)
    assert_includes scope, filters(:two)
    assert_not_includes scope, filters(:solver_one)
    assert_not_includes scope, filters(:ssd_with_subscriptions)
  end
end
