class MessageThreadRenameComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
  end

  def get_error
    flash[:alert]
  end
end
