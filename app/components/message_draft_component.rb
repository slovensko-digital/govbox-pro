class MessageDraftComponent < ViewComponent::Base
  def initialize(message:, is_last:, signable:)
    @message = message
    @is_last = is_last
    @signable = signable
  end
end
