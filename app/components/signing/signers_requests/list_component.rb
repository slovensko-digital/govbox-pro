module Signing
  module SignersRequests
    class ListComponent < ViewComponent::Base
      def initialize(signers_changes:)
        @signers_changes = signers_changes
      end
    end
  end
end
