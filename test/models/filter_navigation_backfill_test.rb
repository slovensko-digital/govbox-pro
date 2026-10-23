require "test_helper"
require Rails.root.join("db/migrate/20261022180300_backfill_personal_filter_navigation")

class FilterNavigationBackfillTest < ActiveSupport::TestCase
  test "populated tenants retain common IDs and subscriptions and gain the previous shortcuts once" do
    # Fixtures represent legacy rows; the additive scope migration classifies
    # those tenant-visible definitions as common, retaining their original IDs.
    Filter.update_all(common: true)
    before_filters = Filter.order(:id).map { |filter| filter.attributes.slice("id", "author_id", "name", "query", "position") }
    before_subscriptions = FilterSubscription.order(:id).map(&:attributes)
    original_ids = tenants(:ssd).filters.order(:position, :id).pluck(:id)
    BackfillPersonalFilterNavigation.new.up
    before_filters.each do |attributes|
      retained = Filter.find(attributes.fetch("id"))
      assert retained.common?
      assert_equal attributes, retained.attributes.slice(*attributes.keys)
    end
    assert_equal before_subscriptions, FilterSubscription.order(:id).map(&:attributes)
    user = users(:basic)
    all = tenants(:ssd).filters.common.find_by!(query: "")
    assert_equal all, user.pinned_filters.first
    assert_equal original_ids, user.pinned_filters.where.not(query: "").limit(original_ids.size).pluck(:id)
    tenants(:ssd).tags.visible.each do |tag|
      assert Filter.for_query(user, "label:(#{tag.name})")
    end
    assert_not FilterPolicy.new(user, filters(:one).reload).edit?
    assert FilterPolicy.new(users(:admin), filters(:one)).edit?
    assert_not Filter.personal.exists?
    assert_empty user.pinned_filters.where(tenant_id: tenants(:solver).id)
  end

  test "retry preserves personal choices and does not create filters for later tags" do
    Filter.update_all(common: true)
    backfill = BackfillPersonalFilterNavigation.new
    backfill.up
    user = users(:basic)
    first = user.pinned_filters.first
    user.set_filter_visibility!(first.id, visible: false)
    before = user.user_filter_visibilities.order(:id).map(&:attributes)
    count = Filter.count
    SimpleTag.create!(tenant: tenants(:ssd), name: "Created after snapshot", visible: true)
    backfill.up
    assert_equal before, user.user_filter_visibilities.order(:id).map(&:attributes)
    assert_equal count, Filter.count
    assert_not Filter.exists?(query: "label:(Created after snapshot)")
    new_user = User.create!(tenant: tenants(:ssd), name: "After backfill", email: "after-backfill@example.com")
    assert_empty new_user.pinned_filters
    assert_equal tenants(:ssd).filters.common.count, new_user.user_filter_visibilities.count
  end

  test "tag shortcut matching an existing saved query is reused" do
    Filter.update_all(common: true)
    tag = tenants(:ssd).tags.visible.first
    filter = filters(:one)
    filter.update!(query: "label:(#{tag.name})")
    BackfillPersonalFilterNavigation.new.up
    assert_equal [filter.id], Filter.common.where(tenant: tenants(:ssd), query: filter.query).pluck(:id)
    assert_equal 1, users(:basic).user_filter_visibilities.where(filter: filter).count
  end

  test "retry reconciles a user created by an older application after the first pass" do
    Filter.update_all(common: true)
    backfill = BackfillPersonalFilterNavigation.new
    backfill.up
    # Bypass new-application callbacks to model an old deployment still creating users.
    legacy = BackfillPersonalFilterNavigation::LegacyUser.create!(tenant_id: tenants(:ssd).id,
      name: "Concurrent legacy user", email: "legacy-during-backfill@example.com")
    assert_empty UserFilterVisibility.where(user_id: legacy.id)
    backfill.up
    user = User.find(legacy.id)
    assert_equal "", user.pinned_filters.first.query
    assert_equal tenants(:ssd).reload.settings.fetch(BackfillPersonalFilterNavigation::SEED_KEY).size,
      user.user_filter_visibilities.count
    assert_not ActiveRecord::Base.connection.index_exists?(:filters, [:tenant_id, :position], unique: true)
  end
end
