module MessageDrafts
  class DocumentSelectionsController < ApplicationController
    before_action :set_message_draft, :set_next_step, :set_message_object_ids

    def new
      authorize @message_draft, "show?"

      if @message_draft.objects.length == 1
        if @next_step == "sign"
          redirect_to new_message_draft_signing_path(@message_draft, object_ids: @message_draft.objects.map(&:id))
        else
          redirect_to edit_message_draft_signature_requests_path(@message_draft, object_ids: @message_draft.objects.map(&:id))
        end
      end
    end

    def update
      authorize @message_draft, "show?"
    end

    private

    def set_next_step
      next_steps = ["sign", "signature_request"]

      @next_step = next_steps.include?(params[:next_step]) ? params[:next_step] : "signature_request"
    end

    def set_message_object_ids
      @message_object_ids = params[:object_ids] || []

      if action_name != "update" && @next_step == "sign" && Current.user.signer?
        @message_object_ids = MessageObject.
          joins(:tags).
          where(message_id: @message_draft).
          where(tags: { id: Current.user.signature_requested_from_tag }).
          pluck(:id).
          map(&:to_s)
      end
    end

    def set_message_draft
      @message_draft = policy_scope(MessageDraft).includes(objects: :tags).find(params[:message_draft_id])
    end
  end
end
