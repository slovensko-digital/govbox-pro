class MessageThreadLogItemComponent < ViewComponent::Base
  with_collection_parameter :message

  def initialize(message:)
    @message = message
  end
end
