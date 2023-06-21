# frozen_string_literal: true

require "test_helper"

class EventBusTest < ActiveSupport::TestCase
  test "should fire matching subscribers" do
    subscriber1 = Minitest::Mock.new
    subscriber1.expect :call, true, [1, 2, 3]

    subscriber2 = Minitest::Mock.new
    subscriber2.expect :perform_later, true, [1, 2, 3]

    subscriber3 = Minitest::Mock.new

    EventBus.subscribe(:event1, subscriber1)
    EventBus.subscribe_job(:event1, subscriber2)
    EventBus.subscribe(:event2, subscriber3)

    EventBus.publish(:event1, 1, 2, 3)

    assert_mock subscriber1
    assert_mock subscriber2
    assert_mock subscriber3
  end
end
