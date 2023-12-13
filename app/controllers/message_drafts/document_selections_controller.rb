module MessageDrafts
  class DocumentSelectionsController < ApplicationController
    before_action :set_message_draft, :set_message_object_ids

    def new
      authorize @message_draft, "show?" # TODO use own policy
    end

    def update
      authorize @message_draft, "show?" # TODO use own policy
    end

    private

    def set_message_object_ids
      @message_object_ids = params[:object_ids] || []
    end

    def set_message_draft
      @message_draft = policy_scope(MessageDraft).includes(objects: :tags).find(params[:message_draft_id])
    end
  end
end
