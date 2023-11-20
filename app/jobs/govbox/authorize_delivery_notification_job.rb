class Govbox::AuthorizeDeliveryNotificationJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

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

    Govbox::SyncBoxJob.set(wait: 2.minutes).perform_later(message.thread.box)
  end

  delegate :uuid, to: self
end
