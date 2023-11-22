class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  def perform(message, upvs_client: UpvsEnvironment.upvs_client)
    edesk_api = upvs_client.api(message.thread.box).edesk

    success = edesk_api.authorize_delivery_notification(message.metadata["delivery_notification"]["authorize_url"])

    unless success
      message.metadata["authorized"] = nil
      message.save!

      raise StandardError, "Delivery notification authorization failed!"
    end

    message.metadata["authorized"] = true
    message.save!

    Govbox::Message.delete_delivery_notification_tag(message)

    Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(message.thread.box)
  end
end
