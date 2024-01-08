module MessageDrafts
  class SigningsController < ApplicationController
    before_action :set_message_draft, :set_message_objects

    def new
      authorize MessageObjectsTag
    end

    def update
      authorize MessageObjectsTag

      if params[:result] == "ok"
        redirect_to message_thread_path(@message_draft.thread, anchor: helpers.dom_id(@message_draft)),
                    notice: t("signing.processed"),
                    status: 303
      else
        redirect_to message_thread_path(@message_draft.thread, anchor: helpers.dom_id(@message_draft)),
                    alert: t("signing.failed"),
                    status: 303
      end
    end

    private

    def set_message_draft
      @message_draft = policy_scope(MessageDraft).find(params[:message_draft_id])
    end

    def message_object_policy_scope
      policy_scope(MessageObject)
    end

    def set_message_objects
      ids = params[:object_ids] || []

      @message_objects = message_object_policy_scope.where(id: ids)
    end
  end
end
