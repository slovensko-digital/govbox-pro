require "test_helper"

class FilterTest < ActiveSupport::TestCase
  test "new thread matching subscription fires event" do
    filter = filters(:ssd_with_subscriptions)

    assert filter.destroy
  end
end
