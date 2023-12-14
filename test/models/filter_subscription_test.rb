require "test_helper"

class FilterSubscriptionTest < ActiveSupport::TestCase
  test "new thread matching subscription fires event" do
    user = users(:admin)
    filter = filters(:one)
    s = FilterSubscription.create!(tenant: user.tenant, user: user, filter: filter, events: ["Notifications::NewMessageThread"])

    m = Govbox::Message.create_message_with_thread!(govbox_messages(:one))

    GoodJob.perform_inline

    assert_equal 1, user.notifications.count
    assert_equal s, user.notifications.last.filter_subscription
    assert_equal m.thread, user.notifications.last.message_thread
  end
end
