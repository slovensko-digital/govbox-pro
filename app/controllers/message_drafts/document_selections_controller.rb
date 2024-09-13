module MessageDrafts
  class DocumentSelectionsController < ApplicationController
    before_action :set_message_draft, :set_next_step, :set_message_object_ids
    before_action :redirect_to_next_step, only: :new

    def new
      authorize @message_draft, "show?"
    end

    def update
      authorize @message_draft, "show?"
    end

    private

    def set_message_draft
      @message_draft = policy_scope(Message).includes(objects: :tags).find(params[:message_draft_id])
    end

    def set_next_step
      next_steps = ["sign", "signature_request"]

      @next_step = next_steps.include?(params[:next_step]) ? params[:next_step] : "signature_request"
    end

    def set_message_object_ids
      @message_object_ids = select_message_objects(@message_draft, @next_step, params[:object_ids] || [])
    end

    def redirect_to_next_step
      if @message_draft.objects.length == 1
        if @next_step == "sign"
          if @message_draft.valid?(:validate_data)
            redirect_to new_message_draft_signing_path(@message_draft, object_ids: @message_draft.objects.map(&:id))
          else
            @message = @message_draft
            render template: 'message_drafts/update_body' and return
          end
        else
          redirect_to edit_message_draft_signature_requests_path(@message_draft, object_ids: @message_draft.objects.map(&:id))
        end
      end
    end

    def select_message_objects(message_draft, next_step, current_ids)
      return current_ids if current_ids.present? || action_name != "new"

      all_ids = message_draft.objects.pluck(:id).map(&:to_s)
      requested_ids = select_requested_object_ids(message_draft).map(&:to_s)

      if next_step == "sign" && Current.user.signer? && requested_ids.present?
        return requested_ids
      end

      all_ids
    end

    def select_requested_object_ids(message_draft)
      MessageObject.
        joins(:tags).
        where(message_id: message_draft).
        where(tags: { id: Current.user.signature_requested_from_tag }).
        pluck(:id)
    end
  end
end
