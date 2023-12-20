class MessageDraftAttachmentsListComponent < ViewComponent::Base

  def initialize(message:)
    @message = message
    @attachments = message.attachments.sort_by(&:created_at).reverse
  end
end
