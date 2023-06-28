class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, notice:)
    @message = message
    @notice = notice
  end
end
