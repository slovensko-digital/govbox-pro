class MessageDraftBodyComponent < ViewComponent::Base

  def initialize(message:, is_last:)
    @message = message
    @is_last = is_last
  end
end
