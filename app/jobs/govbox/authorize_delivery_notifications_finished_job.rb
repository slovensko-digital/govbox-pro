class Govbox::AuthorizeDeliveryNotificationsFinishedJob < ApplicationJob
  queue_as :asap

  def perform(batch, _params)
    batch.properties[:user].notifications.create!(type: Notifications::DeliveryNotificationsAuthorized)
  end
end
