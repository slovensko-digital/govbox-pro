class MessageDraftAttachmentsListComponent < ViewComponent::Base

  def initialize(message:)
    @message = message
    @attachments = message.objects.reject(&:form?).sort_by(&:created_at).reverse
  end
end
