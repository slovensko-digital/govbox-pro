class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  queue_as :highest_priority

  def perform(message, upvs_client: UpvsEnvironment.upvs_client)
    return if message.metadata["authorized"] == true

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

    # folder is not available in UPVS get_message response, therefore we're using corresponding inbox as target folder
    folder = Govbox::Folder.where(box: message.thread.box, name: "Inbox", system: true).first
    Govbox::DownloadMessageJob.set(queue: self.queue_name).perform_later(folder, target_message_id)
  end
end
