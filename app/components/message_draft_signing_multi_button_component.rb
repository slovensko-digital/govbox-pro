class MessageDraftSigningMultiButtonComponent < ViewComponent::Base
  def initialize(message:, signable:)
    @message = message
    @signable = signable
  end
end
