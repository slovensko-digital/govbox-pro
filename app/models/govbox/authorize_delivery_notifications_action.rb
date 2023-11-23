class Govbox::AuthorizeDeliveryNotificationsAction
  def self.run(message_threads)
    messages = message_threads.map(&:messages).flatten

    results = messages.map { |message| ::Govbox::AuthorizeDeliveryNotificationAction.run(message) }

    results.select { |value| value }.present?
  end
end
