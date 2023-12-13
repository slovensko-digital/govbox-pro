require "test_helper"

class FilterSubscriptionTest < ActiveSupport::TestCase
  test "new thread matching subscription fires event" do
    user = users(:admin)
    filter = filters(:one)
    s = FilterSubscription.create!(tenant: user.tenant, user: user, filter: filter, events: ["message_thread_changed"])

    message = Govbox::Message.create_message_with_thread!(govbox_messages(:one))

    Searchable::Indexer.index_message_thread(message.thread) # TODO

    s.create_notifications!

    assert user.notifications.last
  end
end
