class Govbox::BulkAuthorizedDelivery
  def self.run(message_threads)
    message_for_delivery = message_threads.map(&:messages).flatten

    results = message_for_delivery.map { |message| ::Message.authorize_delivery_notification(message) }

    results.select { |value| value }.present?
  end
end
