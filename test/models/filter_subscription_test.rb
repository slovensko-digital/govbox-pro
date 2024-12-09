# == Schema Information
#
# Table name: filter_subscriptions
#
#  id                 :bigint           not null, primary key
#  events             :string           default([]), not null, is an Array
#  last_notify_run_at :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  filter_id          :bigint           not null
#  tenant_id          :bigint           not null
#  user_id            :bigint           not null
#
require "test_helper"

class FilterSubscriptionTest < ActiveSupport::TestCase
  test "new thread matching subscription fires event" do
    user = users(:admin)
    filter = filters(:one)
    s = FilterSubscription.create!(tenant: user.tenant, user: user, filter: filter, events: ["Notifications::NewMessageThread", "Notifications::NewMessage"])

    m = Govbox::Message.create_message_with_thread!(govbox_messages(:one))

    GoodJob.perform_inline

    assert_equal 2, user.notifications.count

    assert_equal s, user.notifications.first.filter_subscription
    assert_equal m.thread, user.notifications.first.message_thread

    assert_equal s, user.notifications.last.filter_subscription
    assert_equal m, user.notifications.last.message
  end
end
