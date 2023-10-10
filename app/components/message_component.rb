class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:)
    @message = message
  end
end
