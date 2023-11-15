require "test_helper"

class Govbox::ProcessMessageJobTest < ActiveJob::TestCase
  test "does not change anything if message already authorized" do
    authorized_message = messages(:authorized_delivery_notification)
    authorized_govbox_message = govbox_messages(:authorized_delivery_notification)

    Govbox::ProcessUnauthorizedDeliveryNotificationJob.new.perform(authorized_govbox_message)

    assert_equal authorized_message.changed?, false
    assert_equal authorized_govbox_message.changed?, false
  end

  test "does not change messages and schedules again if delivery period not expired" do
    message = messages(:delivery_notification)
    govbox_message = govbox_messages(:delivery_notification)

    travel_to Time.new(2023, 07, 01, 01, 04, 44) do
      Govbox::ProcessUnauthorizedDeliveryNotificationJob.new.perform(govbox_message)
    end

    assert_enqueued_with(job: Govbox::ProcessUnauthorizedDeliveryNotificationJob, at: Time.parse(govbox_message.delivery_notification['delivery_period_end_at']))
    assert_equal message.changed?, false
    assert_equal govbox_message.changed?, false
  end

  test "updates message and removes delivery_notification tags if delivery period expired" do
    message = messages(:delivery_notification)
    govbox_message = govbox_messages(:delivery_notification)

    delivery_notification_tag = Tag.find_by!(
      system_name: Govbox::Message::DELIVERY_NOTIFICATION_TAG,
      tenant: message.thread.box.tenant,
    )

    Govbox::ProcessUnauthorizedDeliveryNotificationJob.new.perform(govbox_message)

    message.reload
    message.thread.reload

    assert message.collapsed
    assert_equal message.tags.include?(delivery_notification_tag), false
    assert_equal message.thread.tags.include?(delivery_notification_tag), false
  end
end
