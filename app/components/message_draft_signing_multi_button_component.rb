class MessageDraftSigningMultiButtonComponent < ViewComponent::Base
  def initialize(message:, signable:, agp_enabled: false)
    @message = message
    @signable = signable
    @agp_enabled = agp_enabled
  end
end
