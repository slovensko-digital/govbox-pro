class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, notice:, inbox_tag:)
    @message = message
    @notice = notice
    @inbox_tag = inbox_tag
  end
end
