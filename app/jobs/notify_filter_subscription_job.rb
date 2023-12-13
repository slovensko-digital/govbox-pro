class NotifyFilterSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscription)
    subscription.create_notifications!
  end
end
