class UpdateMessageDraftsAfterMessageTemplatesAdded < ActiveRecord::Migration[7.0]
  def up
    message_reply_template = Upvs::MessageTemplate.find_or_create_by(
      name: MessageTemplate::REPLY_TEMPLATE_NAME,
      content: '<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9">
  <subject>{{Predmet::text_field}}</subject>
  <text>{{Text::text_area}}</text>
</GeneralAgenda>',
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda'
      },
      system: true
    )

    MessageDraft.find_each do |message_draft|
      if message_draft.metadata["original_message_id"].present?
        message_draft.metadata["template_id"] = message_reply_template.id
        message_draft.metadata["data"] = {
          Predmet: message_draft.title,
          Text: message_draft.metadata["message_body"]
        }
        message_draft.save
      end
    end
  end
end
