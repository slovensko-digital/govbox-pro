module Signing
  module DocumentsSelection
    class ActionsComponent < ViewComponent::Base
      def initialize(message_draft:, message_object_ids:, next_step:)
        @message_draft = message_draft
        @message_object_ids = message_object_ids
        @next_step = next_step
      end
    end
  end
end
