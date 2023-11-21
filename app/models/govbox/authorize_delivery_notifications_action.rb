class Govbox::AuthorizeDeliveryNotificationsAction
  def self.run(message_threads)
    messages = message_threads.map(&:messages).flatten

    results = messages.map { |message| ::Message.authorize_delivery_notification(message) }

    results.select { |value| value }.present?
  end
end
