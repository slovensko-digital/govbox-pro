require "test_helper"

class TagFilterCatalogTest < ActiveSupport::TestCase
  test "catalog includes all tags and all messages without changing existing choices" do
    tenant = tenants(:ssd)
    user = users(:basic)
    before = user.pinned_filters.pluck(:id)
    TagFilterCatalog.sync!(tenant)
    assert_equal tenant.tags.count, tenant.filters.where.not(tag_id: nil).count
    assert_equal before, user.pinned_filters.pluck(:id)
    assert_equal "", tenant.filters.find_by!(tag: tags(:ssd_everything)).query
    assert_equal "label:(Hidden)", tenant.filters.find_by!(tag: tags(:ssd_hidden)).query
    assert_no_difference "Filter.count" do
      TagFilterCatalog.sync!(tenant)
    end
  end

  test "new tag filters remain hidden for current and newly initialized users" do
    tenant = tenants(:ssd)
    tenant.enable_feature(:personalized_filters, force: true)
    tag = tenant.tags.create!(type: "SimpleTag", name: "New menu choice")
    filter = tenant.filters.find_by!(tag: tag)
    assert_not users(:basic).user_filter_visibilities.find_by!(filter: filter).visible?
    users(:basic_two).initialize_filter_preferences!
    assert_not users(:basic_two).user_filter_visibilities.find_by!(filter: filter).visible?
    users(:basic).set_filter_visibility!(filter.id, visible: true)
    assert_includes users(:basic).pinned_filters, filter
    assert_not_includes users(:basic_two).pinned_filters, filter
  end

  test "signer choices are available only to their owner including for administrators" do
    tenant = tenants(:ssd)
    TagFilterCatalog.sync!(tenant)
    own = tenant.filters.find_by!(tag: tags(:ssd_basic_user_signature_requested))
    other = tenant.filters.find_by!(tag: tags(:ssd_signer_user_signature_requested))
    group = tenant.filters.find_by!(tag: tags(:ssd_signers_signature_requested))
    assert_includes Filter.available_to(users(:basic)), own
    assert_not_includes Filter.available_to(users(:basic)), other
    assert_not_includes Filter.available_to(users(:basic)), group
    assert_not_includes Filter.available_to(users(:admin)), own
    assert_raises(ActiveRecord::RecordNotFound) { users(:basic).set_filter_visibility!(other.id, visible: true) }
  end
end
