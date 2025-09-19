module Signing
  class ProcessingComponent < ViewComponent::Base
    def initialize(message_objects:, signature_settings:, after_singing_path:)
      @message_objects = message_objects
      @signature_settings = signature_settings
      @after_singing_path = after_singing_path
    end
  end
end
