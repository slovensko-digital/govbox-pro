require "test_helper"

class FilterSubscriptionTest < ActiveSupport::TestCase
  test "new thread matching subscription fires event" do
    user = users(:basic)
    filter = filters(:one)
    s = FilterSubscription.create!(user: user, filter: filter, events: ["message_thread_created"])

    message = Govbox::Message.create_message_with_thread!(govbox_messages(:one))

    GoodJob.perform_inline

    assert user.notifications.last
  end
end
