require "test_helper"

class FilterMenuReadTest < ActiveSupport::TestCase
  test "reading a multi-filter menu is one query with no writes" do
    user = users(:basic)
    12.times do |i|
      filter = Filter.create!(tenant: user.tenant, author: user, name: "Menu #{i}", query: "menu-#{i}")
      user.set_filter_visibility!(filter.id, visible: true)
    end
    statements = []
    subscriber = ->(*args) do
      payload = args.last
      statements << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached]
    end
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        assert_equal 12, user.pinned_filters.to_a.size
      end
    end
    assert_equal 1, statements.size
    assert_match(/\ASELECT/, statements.first)
  end
end
