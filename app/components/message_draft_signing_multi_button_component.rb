class MessageDraftSigningMultiButtonComponent < ViewComponent::Base
  def initialize(message:, user_is_signer: false)
    @message = message
    @user_is_signer = user_is_signer
  end
end
