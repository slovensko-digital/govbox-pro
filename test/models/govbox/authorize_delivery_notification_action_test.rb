require "test_helper"

class Govbox::AuthorizeDeliveryNotificationActionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "schedules Govbox::AuthorizeDeliveryNotificationJob with highest priority" do
    message = messages(:solver_main_delivery_notification_two)

    assert_enqueued_with(job: Govbox::AuthorizeDeliveryNotificationJob, priority: -1000) do
      Govbox::AuthorizeDeliveryNotificationAction.run(message)
    end
  end
end
