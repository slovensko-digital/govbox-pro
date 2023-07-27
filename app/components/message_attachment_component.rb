class MessageAttachmentComponent < ViewComponent::Base
  def initialize(message_attachment:, message_attachment_iteration:)
    @message_attachment = message_attachment
    @is_last = message_attachment_iteration.last?
    @destroy_allowed = message_attachment.message.is_a?(MessageDraft) && message_attachment.message.not_yet_submitted?
  end
end
