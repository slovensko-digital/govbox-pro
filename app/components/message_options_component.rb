class MessageOptionsComponent < ViewComponent::Base
  def initialize(message:, mode:)
    @message = message
    @mode = mode
  end
end
