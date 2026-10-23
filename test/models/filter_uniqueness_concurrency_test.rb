require "test_helper"

class FilterUniquenessConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "concurrent common creates cannot claim the same query" do
    query = "concurrent-#{SecureRandom.hex(8)}"
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            results << Filter.create!(tenant: tenants(:ssd), name: "Concurrent", common: true, query: query)
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
            results << error
          end
        end
      end
    end
    threads.each(&:join)
    assert_equal 1, Filter.where(query: query).count
    assert_equal 1, 2.times.map { results.pop }.count { |result| result.is_a?(Filter) }
  ensure
    Filter.where(query: query).destroy_all if query
  end

  test "concurrent pinning serializes positions for one user" do
    query = "pinning-#{SecureRandom.hex(8)}"
    filters = 2.times.map { |i| Filter.create!(tenant: tenants(:ssd), common: true, name: "Pin #{i}", query: "#{query}-#{i}") }
    threads = filters.map do |filter|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          User.find(users(:basic).id).set_filter_visibility!(filter.id, visible: true)
        end
      end
    end
    threads.each(&:value)
    preferences = users(:basic).user_filter_visibilities.where(filter: filters)
    assert_equal 2, preferences.count
    assert_equal 2, preferences.pluck(:position).uniq.size
  ensure
    filters&.each(&:destroy!)
  end

  test "publication racing onboarding gives exactly one preference" do
    query = "onboarding-#{SecureRandom.hex(8)}"
    tenant_id = tenants(:ssd).id
    threads = [
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Filter.create!(tenant_id: tenant_id, common: true, name: "Racing", query: query)
        end
      end,
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          User.create!(tenant_id: tenant_id, name: query, email: "#{query}@example.com")
        end
      end
    ]
    common, user = threads.map(&:value)
    assert_equal 1, user.user_filter_visibilities.where(filter: common).count
    assert_includes user.pinned_filters, common
  ensure
    User.find_by(email: "#{query}@example.com")&.destroy! if query
    Filter.where(query: query).destroy_all if query
  end
end
