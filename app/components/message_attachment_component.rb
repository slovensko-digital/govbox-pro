class MessageAttachmentComponent < ViewComponent::Base
  def initialize(message_attachment:)
    @message_attachment = message_attachment
  end
end
