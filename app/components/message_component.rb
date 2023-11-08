class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, mode:)
    @message = message
    @mode = mode
  end
end
