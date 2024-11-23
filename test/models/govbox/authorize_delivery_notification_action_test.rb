require "test_helper"

class Govbox::AuthorizeDeliveryNotificationActionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "schedules Govbox::AuthorizeDeliveryNotificationJob with highest priority" do
    message = messages(:solver_main_delivery_notification_two)

    Govbox::AuthorizeDeliveryNotificationAction.run(message)
    assert_equal "Govbox::AuthorizeDeliveryNotificationJob", GoodJob::Job.last.job_class
    assert_equal -1000, GoodJob::Job.last.priority
  end
end
