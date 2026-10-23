require "test_helper"

class NotifyFilterSubscriptionJobTest < ActiveSupport::TestCase
  test "serialized queued job is safely discarded after its subscription is deleted" do
    filter = Filter.create!(tenant: tenants(:ssd), common: true, name: "Queued", query: "queued-deletion")
    subscription = FilterSubscription.create!(tenant: tenants(:ssd), user: users(:basic), filter: filter, events: ["Notifications::NewMessage"])
    serialized = NotifyFilterSubscriptionJob.new(subscription, message_threads(:ssd_main_general), false).serialize
    filter.destroy_with_confirmation(token: filter.deletion_confirmation)
    assert_no_difference "Notification.count" do
      NotifyFilterSubscriptionJob.execute(serialized)
    end
  end

  test "deletion follows existing notification foreign keys without dangling history links" do
    user = users(:basic)
    filter = Filter.create!(tenant: user.tenant, common: true, name: "History", query: "history-deletion")
    subscription = FilterSubscription.create!(tenant: user.tenant, user: user, filter: filter, events: ["Notifications::NewMessageThread"])
    linked = user.notifications.create!(type: "Notifications::NewMessageThread", message_thread: message_threads(:ssd_main_general), filter_subscription: subscription, filter_name: filter.name)
    unrelated = user.notifications.create!(type: "Notifications::NewMessageThread", message_thread: message_threads(:ssd_main_general), filter_name: "Unrelated")
    thread_id = linked.message_thread_id
    filter.destroy_with_confirmation(token: filter.deletion_confirmation)
    assert_not Notification.exists?(linked.id)
    assert Notification.exists?(unrelated.id)
    assert MessageThread.exists?(thread_id)
    assert_not Notification.where.not(filter_subscription_id: nil).where.not(filter_subscription_id: FilterSubscription.select(:id)).exists?
  end
end
