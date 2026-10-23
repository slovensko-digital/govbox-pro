require "test_helper"

class FilterTest < ActiveSupport::TestCase
  test "new filters are personal and require an owner in the same tenant" do
    filter = Filter.new(tenant: tenants(:ssd), name: "Personal", query: "invoice")
    assert_not filter.common?
    assert_not filter.valid?
    filter.author = users(:basic)
    assert filter.valid?
    filter.author = users(:solver_other)
    assert_not filter.valid?
    assert filter.errors[:author].any?
  end

  test "common all-messages filter permits an empty query and no author" do
    filter = Filter.create!(tenant: tenants(:ssd), name: "All", common: true, query: "")
    assert_equal "", filter.reload.query
    assert_nil filter.author
  end

  test "trim only outer whitespace and retain query syntax" do
    filter = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Invoices",
      query: " \tlabel:(NASES)  Faktúra\n")
    assert_equal "label:(NASES)  Faktúra", filter.reload.query
    filter.query = nil
    assert_not filter.valid?
  end

  test "queries are unique per personal owner or common tenant but can overlap" do
    common = Filter.create!(tenant: tenants(:ssd), name: "Common", common: true, query: "unique")
    personal = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Personal", query: " unique ")
    other = Filter.create!(tenant: tenants(:ssd), author: users(:basic_two), name: "Other", query: "unique")
    assert_not common.dup.valid?
    assert_not personal.dup.valid?
    assert other.persisted?
    assert Filter.create!(tenant: tenants(:solver), name: "Other tenant", common: true, query: "unique").persisted?
    personal.query = "Unique"
    assert personal.save
  end

  test "database rejects same-scope duplicates even without validation" do
    existing = Filter.create!(tenant: tenants(:ssd), name: "Common", common: true, query: "db-unique")
    assert_raises ActiveRecord::RecordNotUnique do
      Filter.transaction(requires_new: true) do
        Filter.insert_all!([existing.attributes.except("id").merge("position" => 9999)])
      end
    end
  end

  test "tag creation and rename do not create filters or rewrite literal queries" do
    tag = nil
    assert_no_difference "Filter.count" do
      tag = SimpleTag.create!(tenant: tenants(:ssd), name: "Original query label")
    end
    filter = Filter.create!(tenant: tenants(:ssd), author: users(:basic), name: "Literal label", query: "label:(Original query label)")
    assert_no_difference "Filter.count" do
      tag.update!(name: "Renamed query label")
    end
    assert_equal "label:(Original query label)", filter.reload.query
  end
end
