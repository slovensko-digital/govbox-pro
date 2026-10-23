require "test_helper"

class FilterResolutionTest < ActiveSupport::TestCase
  test "only own personal and tenant common definitions are available" do
    common = Filter.create!(tenant: tenants(:ssd), name: "Common", common: true, query: "resolution")
    own = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Own", query: "own-resolution")
    other = Filter.create!(tenant: tenants(:ssd), author: users(:basic_two), name: "Other", query: "other-resolution")
    foreign = Filter.create!(tenant: tenants(:solver), name: "Foreign", common: true, query: "foreign-resolution")
    available = Filter.available_to(users(:basic))
    assert_includes available, common
    assert_includes available, own
    assert_not_includes available, other
    assert_not_includes available, foreign
  end

  test "personal definition wins without requiring a menu pin" do
    common = Filter.create!(tenant: tenants(:ssd), name: "Common", common: true, query: "resolution")
    own = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Own", query: "resolution")
    users(:basic).set_filter_visibility!(own.id, visible: false)
    assert_equal own, Filter.for_query(users(:basic), " resolution ")
    assert_not_includes Filter.effective_for(users(:basic)), common
    assert_equal common, Filter.for_query(users(:basic_two), "resolution")
  end

  test "a common query edit can collide with a personal definition" do
    common = Filter.create!(tenant: tenants(:ssd), name: "Common", common: true, query: "before-edit")
    own = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Own", query: "after-edit")
    common.update!(query: "after-edit")
    assert_equal own, Filter.for_query(users(:basic), "after-edit")
    assert_equal common, Filter.for_query(users(:basic_two), "after-edit")
    assert_nil Filter.for_query(users(:basic), "before-edit")
    assert_nil Filter.for_query(users(:solver_other), "after-edit")
  end
end
