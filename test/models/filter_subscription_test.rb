require "test_helper"
require "helpers/good_job_helper"

class FilterSubscriptionTest < ActiveSupport::TestCase
  include GoodJobHelper
  test "new thread matching subscription fires event" do
    user = users(:admin)
    filter = filters(:one)
    filter.update!(common: true)
    s = FilterSubscription.create!(tenant: user.tenant, user: user, filter: filter, events: ["Notifications::NewMessageThread", "Notifications::NewMessage"])

    m = Govbox::Message.create_message_with_thread!(govbox_messages(:one))

    GoodJob.perform_inline

    assert_equal 2, user.notifications.count

    assert_equal s, user.notifications.first.filter_subscription
    assert_equal m.thread, user.notifications.first.message_thread

    assert_equal s, user.notifications.last.filter_subscription
    assert_equal m, user.notifications.last.message
  end

  test "personal override lifecycle and unpinning preserve the common subscription and delivery" do
    filters(:one).destroy!
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, common: true, name: "Shared general", query: "general")
    subscription = FilterSubscription.create!(tenant: user.tenant, user: user, filter: common, events: ["Notifications::NewMessageThread"])
    before = subscription.reload.attributes
    personal = Filter.create!(tenant: user.tenant, author: user, name: "My general", query: common.query)
    assert_equal before, subscription.reload.attributes
    assert_equal 1, FilterSubscription.for_query(user, common.query).count
    user.set_filter_visibility!(personal.id, visible: false)
    assert_equal before, subscription.reload.attributes
    Searchable::MessageThread.reindex_all
    thread = message_threads(:ssd_main_general)
    assert Searchable::MessageThread.matching(subscription).where(message_thread: thread).exists?
    assert_difference -> { user.notifications.count }, 1 do
      NotifyFilterSubscriptionJob.perform_now(subscription, thread, false)
    end
    after_delivery = subscription.reload.attributes
    personal.destroy!
    user.set_filter_visibility!(common.id, visible: false)
    assert_equal after_delivery, subscription.reload.attributes
    assert Searchable::MessageThread.matching(subscription).where(message_thread: thread).exists?
  end

  test "publishing a filter grants neither box nor tag access to results and notifications" do
    user = users(:basic)
    common = Filter.create!(tenant: user.tenant, name: "All authorized", query: "", common: true)
    subscription = FilterSubscription.create!(tenant: user.tenant, user: user, filter: common, events: ["Notifications::NewMessageThread"])
    Searchable::MessageThread.reindex_all
    thread = message_threads(:ssd_main_general)
    assert Searchable::MessageThread.matching(subscription).where(message_thread: thread).exists?

    user.groups.update_all(all_boxes_permission: false)
    BoxGroup.where(group_id: user.groups.select(:id)).delete_all
    assert_empty Searchable::MessageThread.matching(subscription)
    assert_no_difference -> { user.notifications.count } do
      NotifyFilterSubscriptionJob.perform_now(subscription, thread, false)
    end
    assert_empty MessageThreadPolicy::Scope.new(user, MessageThread).resolve

    TagGroup.where(group_id: user.groups.select(:id)).delete_all
    assert_empty Searchable::MessageThread.matching(subscription)
    assert Filter.available_to(user).exists?(common.id)
  end
end
