class MessageAttachmentComponent < ViewComponent::Base
  def initialize(message_attachment, is_last)
    @message_attachment = message_attachment
    @is_last = is_last
  end
end
