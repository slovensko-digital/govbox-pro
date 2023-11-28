class MessageDraftAttachmentsListComponent < ViewComponent::Base

  def initialize(message:)
    @message = message
    @attachments = message.attachments.sort_by(&:created_at).reverse
    @unsigned_attachments = @attachments.reject(&:is_signed)
  end
end
