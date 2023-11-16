class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  retry_on StandardError, wait: 2.minutes, attempts: 5

  def perform(message, upvs_client: UpvsEnvironment.upvs_client, schedule_sync: true)
    edesk_api = upvs_client.api(message.thread.folder.box).edesk

    success = edesk_api.authorize_delivery_notification(message.metadata["delivery_notification"]["authorize_url"])

    unless success
      message.metadata["authorized"] = nil
      message.save!

      raise StandardError, "Delivery notification authorization failed!"
    end

    message.metadata["authorized"] = true
    message.save!

    Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(message.thread.folder.box) if schedule_sync
  end

  delegate :uuid, to: self
end
