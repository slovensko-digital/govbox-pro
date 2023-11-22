class MessageAttachmentComponent < ViewComponent::Base
  def initialize(message_attachment:, message_attachment_iteration:)
    @message_attachment = message_attachment
    @is_last = message_attachment_iteration.last?
  end
end
