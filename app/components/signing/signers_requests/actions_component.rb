module Signing
  module SignersRequests
    class ActionsComponent < ViewComponent::Base
      def initialize(message_draft:, signers_changes:)
        @message_draft = message_draft
        @signers_changes = signers_changes
      end
    end
  end
end
