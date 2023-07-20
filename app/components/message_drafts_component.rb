class MessageDraftsComponent < ViewComponent::Base

  def initialize(message:, notice:)
    @message = message
    @notice = notice
  end
end
