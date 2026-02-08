require "test_helper"

class Govbox::AuthorizeDeliveryNotificationsActionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "schedules Govbox::AuthorizeDeliveryNotificationJob with highest priority" do
    message_thread = message_threads(:ssd_main_general)

    assert_enqueued_with(job: Govbox::AuthorizeDeliveryNotificationJob, priority: -1000) do
      Govbox::AuthorizeDeliveryNotificationsAction.run([message_thread])
    end

    assert_enqueued_with(job: Govbox::AuthorizeDeliveryNotificationsFinishedJob, priority: -1000) do
      Govbox::AuthorizeDeliveryNotificationsAction.run([message_thread])
    end
  end
end
