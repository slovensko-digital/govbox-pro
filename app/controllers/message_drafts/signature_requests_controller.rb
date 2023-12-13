module MessageDrafts
  class SignatureRequestsController < ApplicationController
    before_action :set_message_draft, :set_message_objects

    def edit
      authorize @message_draft, "show?" # TODO use own policy

      @signers_changes = RelationChanges::Signers.new(
        signers_scope: signers_scope,
        assignments: RelationChanges::Signers.build_signature_requested_assignments(
          message_objects: @message_objects,
          signers_scope: signers_scope
        )
      )
    end

    def prepare
      authorize @message_draft, "show?" # TODO use own policy

      @signers_changes = RelationChanges::Signers.new(
        signers_scope: signers_scope,
        assignments: signers_assignments
      )
    end

    def update
      authorize @message_draft, "show?" # TODO use own policy

      signers_changes = RelationChanges::Signers.new(
        signers_scope: signers_scope.includes(tenant: :signature_requested_tag),
        assignments: signers_assignments
      )

      signers_changes.save(@message_objects)

      # status: 303 is needed otherwise PATCH is kept in the following redirect https://apidock.com/rails/ActionController/Redirecting/redirect_to
      redirect_to message_thread_path(@message_draft.thread, anchor: helpers.dom_id(@message_draft)),
                  notice: "Podpisové štítky boli upravené",
                  status: 303
    end

    private

    def set_message_draft
      @message_draft = policy_scope(MessageDraft).find(params[:message_draft_id])
    end

    def signers_scope
      Current.tenant.signer_group.users.order(name: :asc)
    end

    def signer_scope
      Current.tenant.signer_group.users.order(:name)
    end

    def message_object_policy_scope
      policy_scope(MessageObject)
    end

    def set_message_objects
      ids = params[:object_ids] || []

      @message_objects = message_object_policy_scope.where(id: ids)
    end

    def signers_assignments
      params.require(:assignments).permit(init: {}, new: {})
    end
  end
end
