require "test_helper"
require "helpers/good_job_helper"

class NotifyFilterSubscriptionJobTest < ActiveJob::TestCase
  include GoodJobHelper

  setup do
    @thread = message_threads(:ssd_main_general)
    @subscriptions = [users(:basic), users(:basic_two), users(:admin)].map do |user|
      FilterSubscription.create!(tenant: @thread.tenant, user: user, filter: filters(:ssd_with_subscriptions), events: ["Notifications::NewMessage"])
    end
  end

  test "enqueues a job for every subscription matching the thread" do
    @subscriptions.each { |subscription| NotifyFilterSubscriptionJob.perform_later(subscription, @thread, false) }

    assert_equal 3, GoodJob::Job.count
  end

  test "limits the unfinished jobs for a subscription and thread" do
    3.times { NotifyFilterSubscriptionJob.perform_later(@subscriptions.first, @thread, false) }

    assert_equal 2, GoodJob::Job.count
  end
end
