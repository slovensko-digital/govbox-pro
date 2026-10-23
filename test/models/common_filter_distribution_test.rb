require "test_helper"

class CommonFilterDistributionTest < ActiveSupport::TestCase
  test "publication stays hidden and retries preserve choices" do
    user = users(:basic)
    user.set_filter_visibility!(filters(:one).id, visible: true)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Published", query: "published")
    assert_equal [filters(:one)], user.pinned_filters.to_a
    assert_empty users(:basic_two).pinned_filters
    assert_empty users(:solver_other).user_filter_visibilities.where(filter: common)
    user.set_filter_visibility!(common.id, visible: false)
    preference = user.user_filter_visibilities.find_by!(filter: common)
    before = preference.attributes
    common.distribute!
    assert_equal before, preference.reload.attributes
    assert_equal 1, user.user_filter_visibilities.where(filter: common).count
  end

  test "a personal duplicate is acknowledged without pinning the common default" do
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Personal", query: "publish-duplicate")
    users(:basic).set_filter_visibility!(personal.id, visible: false)
    common = Filter.create!(tenant: tenants(:ssd), common: true, name: "Common", query: personal.query)
    preference = users(:basic).user_filter_visibilities.find_by!(filter: common)
    assert_not preference.visible?
    common.distribute!
    assert_not preference.reload.visible?
    assert_not_includes users(:basic_two).pinned_filters, common
  end

  test "new users start with hidden choices and initialization preserves chosen order" do
    first = Filter.create!(tenant: tenants(:ssd), common: true, name: "First", query: "onboard-first")
    second = Filter.create!(tenant: tenants(:ssd), common: true, name: "Second", query: "onboard-second")
    user = User.create!(tenant: tenants(:ssd), name: "New filter user", email: "new-filter-user@example.com")
    assert_empty user.pinned_filters
    user.set_filter_visibility!(first.id, visible: true)
    user.set_filter_visibility!(second.id, visible: true)
    user.reorder_filters!([second.id, first.id])
    user.initialize_filter_preferences!
    assert_equal [second, first], user.pinned_filters.to_a
  end

  test "fresh tenant all-messages default is an empty query not an everything label" do
    tenant = Tenant.create!(name: "Fresh filter tenant")
    user = User.create!(tenant: tenant, name: "Fresh user", email: "fresh-filter-user@example.com")
    assert_equal 1, tenant.filters.count
    assert tenant.filters.first.common?
    assert_equal "", tenant.filters.first.query
    assert_empty user.pinned_filters
  end
end
