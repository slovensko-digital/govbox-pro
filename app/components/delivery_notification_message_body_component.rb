class DeliveryNotificationMessageBodyComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
