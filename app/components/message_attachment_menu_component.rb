class MessageAttachmentMenuComponent < ViewComponent::Base
  include Attachments

  def initialize(message:,message_attachment:)
    @message = message
    @message_attachment = message_attachment
  end
end
