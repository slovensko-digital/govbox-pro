class MessageDraftComponent < ViewComponent::Base
  def initialize(message:, is_last:, user_is_signer:)
    @message = message
    @is_last = is_last
    @user_is_signer = user_is_signer
  end
end
