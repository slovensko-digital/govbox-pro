class MessageDraftComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
