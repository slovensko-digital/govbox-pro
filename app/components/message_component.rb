class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, notice:, available_tags:)
    @message = message
    @notice = notice
    @available_tags = available_tags
  end
end
