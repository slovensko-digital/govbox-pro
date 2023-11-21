class AddFormTemplateIdToMessageDrafts < ActiveRecord::Migration[7.0]
  def change
    MessageDraft.find_each do |message_draft|
      upvs_form = Upvs::Form.find_by(
        identifier: message_draft.metadata["posp_id"],
        version: message_draft.metadata["posp_version"],
        message_type: message_draft.metadata["message_type"]
      )
      upvs_form_template = upvs_form.templates.where(tenant: message_draft.thread.tenant).or(upvs_form.templates.where(tenant: nil))&.take

      message_draft.metadata["form_template_id"] = upvs_form_template
      message_draft.save
    end
  end
end
