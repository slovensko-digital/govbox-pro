require "test_helper"
require Rails.root.join("db/migrate/20261022180100_finalize_filter_query_uniqueness")
require Rails.root.join("db/migrate/20261022180300_backfill_personal_filter_navigation")

class FilterQueryPreflightTest < ActiveSupport::TestCase
  test "preflight reports trimmed collisions without merging filters or subscriptions" do
    first = Filter.create!(tenant: tenants(:ssd), name: "First", query: "preflight", common: true)
    attributes = first.attributes.except("id").merge("query" => " preflight ", "position" => 9999)
    second_id = Filter.insert_all!([attributes]).rows.first.first
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: first,
      events: ["Notifications::NewMessage"])
    before = subscription.reload.attributes

    report = FinalizeFilterQueryUniqueness.new.collision_report
    assert_equal 1, report.size
    assert_includes report.first["filter_ids"].to_s, first.id.to_s
    assert_includes report.first["filter_ids"].to_s, second_id.to_s
    assert_equal 1, report.first["subscribing_users"].to_i
    error = assert_raises(RuntimeError) { FinalizeFilterQueryUniqueness.new.up }
    assert_includes error.message, "explicit resolution"
    assert_no_difference "Filter.count" do
      assert_raises(RuntimeError) { BackfillPersonalFilterNavigation.new.up }
    end
    assert_equal before, subscription.reload.attributes
    assert_equal " preflight ", Filter.find(second_id).query
  end
end
