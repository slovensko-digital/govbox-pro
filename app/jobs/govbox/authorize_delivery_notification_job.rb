class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  def perform(message, upvs_client: UpvsEnvironment.upvs_client)
    edesk_api = upvs_client.api(message.thread.box).edesk

    success, target_message_id = edesk_api.authorize_delivery_notification(message.metadata["delivery_notification"]["authorize_url"], mode: :sync)

    if success
      message.metadata["authorized"] = true
      message.save!
    else
      message.metadata["authorized"] = nil
      message.save!
      Govbox::Message.add_delivery_notification_tag(message)
      raise StandardError, "Delivery notification authorization failed!"
    end

    raise StandardError, "Target message download failed" unless target_message_id

    Govbox::DownloadMessageJob.perform_later(box: message.thread.box, target_message_id)
  end

end
