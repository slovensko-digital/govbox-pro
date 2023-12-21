module Signing
  class ProcessingComponent < ViewComponent::Base
    def initialize(message_draft:, message_objects:)
      @message_draft = message_draft
      @message_objects = message_objects
    end
  end
end
