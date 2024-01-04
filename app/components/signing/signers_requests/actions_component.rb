module Signing
  module SignersRequests
    class ActionsComponent < ::Common::ModalActionsComponent
      def initialize(message_draft:, signers_changes:)
        @message_draft = message_draft
        @signers_changes = signers_changes
      end
    end
  end
end
