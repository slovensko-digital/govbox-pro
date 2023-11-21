class MessageAttachmentComponent < ViewComponent::Base
  include Attachments

  def initialize(message_attachment:, message:, message_attachment_iteration:)
    @message_attachment = message_attachment
    @message = message
    @is_last = message_attachment_iteration.last?
  end
end
