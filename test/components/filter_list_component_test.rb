require "test_helper"

class FilterListComponentTest < ViewComponent::TestCase
  test "personal menu order, name and query active state" do
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Common", query: "component-query")
    personal = Filter.create!(tenant: user.tenant, author: user, name: "Personal", query: common.query)
    other = Filter.create!(tenant: user.tenant, author: user, name: "Other", query: "other-component")
    user.set_filter_visibility!(personal.id, visible: true)
    user.set_filter_visibility!(other.id, visible: true)
    user.reorder_filters!([other.id, personal.id])
    render_inline(Layout::FilterListComponent.new(filters: user.pinned_filters.to_a, query: personal.query))
    assert_equal ["Other", "Personal"], page.all("a").map { |link| link.text.strip }
    assert_selector 'a[data-active="true"]', text: "Personal"
    assert_selector 'a[href="/message_threads?q=component-query"]', text: "Personal"
    assert_no_selector 'a', text: "Common"
    assert_empty users(:basic_two).pinned_filters
  end

  test "unpinned personal winner excludes the pinned common duplicate" do
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Common hidden", query: "hidden-component")
    personal = Filter.create!(tenant: user.tenant, author: user, name: "Personal hidden", query: common.query)
    user.set_filter_visibility!(common.id, visible: true)
    user.set_filter_visibility!(personal.id, visible: false)
    render_inline(Layout::FilterListComponent.new(filters: user.pinned_filters.to_a, query: common.query))
    assert_no_selector "a"
  end
end
