require "test_helper"

class FilterTest < ActiveSupport::TestCase
  test "is destroyable" do
    filter = filters(:ssd_with_subscriptions)

    assert filter.destroy
  end
end
