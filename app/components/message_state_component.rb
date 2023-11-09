class MessageStateComponent < ViewComponent::Base

  def initialize(message:, classes:"")
    @message = message
    @classes = classes
  end
end
