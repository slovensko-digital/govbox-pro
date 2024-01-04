module Signing
  module DocumentsSelection
    class Component < ViewComponent::Base
      ACTIONS_FRAME = "documents-selections-actions"

      def initialize(message_draft:, message_object_ids:, next_step:)
        @message_draft = message_draft
        @form = message_draft.form
        @attachments = message_draft.objects.to_a.reject(&:form?).sort_by(&:created_at).reverse
        @message_object_ids = message_object_ids
        @next_step = next_step
      end
    end
  end
end
