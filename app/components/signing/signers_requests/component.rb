module Signing
  module SignersRequests
    class Component < ViewComponent::Base
      DIFF_FRAME = "signers-assignment-diff"
      ACTIONS_FRAME = "signers-assignment-actions"

      def initialize(message_draft:, message_objects:, signers_changes:)
        @message_draft = message_draft
        @message_objects = message_objects
        @signers_changes = signers_changes
      end
    end
  end
end
