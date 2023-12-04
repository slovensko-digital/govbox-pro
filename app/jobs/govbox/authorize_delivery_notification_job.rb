class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  def perform(message, upvs_client: UpvsEnvironment.upvs_client)
    edesk_api = upvs_client.api(message.thread.box).edesk

    success, target_message_id = edesk_api.authorize_delivery_notification(message.metadata["delivery_notification"]["authorize_url"], mode: :sync)

    handle_failed_authorization unless success

    message.metadata["authorized"] = true
    message.save!

    raise StandardError, "Target message download failed" unless target_message_id
    raise StandardError, "Target message download failed" unless edesk_api.fetch_message(target_message_id)

    # Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(message.thread.box)
  end

  def handle_failed_authorization
    message.metadata["authorized"] = nil
    message.save!

    Govbox::Message.add_delivery_notification_tag(message)

    raise StandardError, "Delivery notification authorization failed!"
  end
end
