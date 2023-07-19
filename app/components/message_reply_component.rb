class MessageReplyComponent < ViewComponent::Base

  def initialize(message:, message_reply:, notice:)
    @message = message
    @message_reply = message_reply
    @notice = notice
  end
end
