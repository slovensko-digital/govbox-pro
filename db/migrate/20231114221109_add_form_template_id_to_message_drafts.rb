class AddFormTemplateIdToMessageDrafts < ActiveRecord::Migration[7.0]
  def change
    MessageDraft.find_each do |message_draft|
      message_draft.metadata["form_template_id"] = Upvs::Form.find_by(
        identifier: message_draft.metadata["posp_id"],
        version: message_draft.metadata["posp_version"],
        message_type: message_draft.metadata["message_type"]
      )
      message_draft.save
    end
  end
end
