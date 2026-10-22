require "test_helper"

class FilterPinningTest < ActiveSupport::TestCase
  test "unpin persists, repin appends, and ordering belongs to one user" do
    user = users(:basic)
    first = filters(:one)
    second = filters(:two)
    second.update!(common: true)
    user.set_filter_visibility!(first.id, visible: true)
    user.set_filter_visibility!(second.id, visible: true)
    users(:basic_two).set_filter_visibility!(second.id, visible: true)
    user.set_filter_visibility!(first.id, visible: false)
    assert_equal [second], user.reload.pinned_filters.to_a
    user.set_filter_visibility!(first.id, visible: true)
    assert_equal [second, first], user.pinned_filters.to_a
    user.reorder_filters!([first.id, second.id])
    assert_equal [first, second], user.pinned_filters.to_a
    assert_equal [second], users(:basic_two).pinned_filters.to_a
    assert_raises(ActiveRecord::RecordNotFound) { user.reorder_filters!([filters(:solver_one).id]) }
  end

  test "personal override exclusion and deletion preserve common original position" do
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Common", query: "restore")
    preference = user.set_filter_visibility!(common.id, visible: true)
    original_position = preference.position
    personal = Filter.create!(tenant: user.tenant, author: user, name: "Personal", query: "restore")
    user.set_filter_visibility!(personal.id, visible: false)
    assert_not_includes user.pinned_filters, common
    personal.destroy!
    assert_equal common, user.pinned_filters.first
    assert_equal original_position, preference.reload.position
    assert preference.visible?
  end

  test "deleting personal override does not repin explicitly unpinned common" do
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Common", query: "restore-hidden")
    preference = user.set_filter_visibility!(common.id, visible: false)
    personal = Filter.create!(tenant: user.tenant, author: user, name: "Personal", query: "restore-hidden")
    personal.destroy!
    assert_empty user.pinned_filters
    assert_not preference.reload.visible?
  end
end
