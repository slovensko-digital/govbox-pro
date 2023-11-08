class MessageOptionsComponent < ViewComponent::Base
  def initialize(message:, mode: :thread_view)
    @message = message
    @mode = mode
  end
end
