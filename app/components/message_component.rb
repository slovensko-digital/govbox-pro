class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, mode:)
    @message = message
    @attachments = message.objects.reject(&:form?)
    @mode = mode
  end
end
