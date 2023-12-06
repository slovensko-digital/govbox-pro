class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  def perform(message, upvs_client: UpvsEnvironment.upvs_client)
    edesk_api = upvs_client.api(message.thread.box).edesk

    success, target_message_id = edesk_api.authorize_delivery_notification(message.metadata["delivery_notification"]["authorize_url"], mode: :sync)

    handle_failed_authorization unless success

    message.metadata["authorized"] = true
    message.save!

    raise StandardError, "Target message download failed" unless target_message_id
    raise StandardError, "Target message download failed" unless run_download_job(message, target_message_id)
  end

  def handle_failed_authorization
    message.metadata["authorized"] = nil
    message.save!

    Govbox::Message.add_delivery_notification_tag(message)

    raise StandardError, "Delivery notification authorization failed!"
  end

  def run_download_job(message, message_id)
    folder = message.thread.box.folders.select(&:inbox?).first
    Govbox::DownloadMessageJob.perform_later(folder, message_id)
  end
end
