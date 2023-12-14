module Signing
  module DocumentsSelection
    class ActionsComponent < ViewComponent::Base
      def initialize(message_draft:, message_object_ids:)
        @message_draft = message_draft
        @message_object_ids = message_object_ids
      end
    end
  end
end
