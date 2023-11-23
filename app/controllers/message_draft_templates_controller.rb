class MessageDraftTemplatesController < ApplicationController
  before_action :load_message_draft_template

  def recipients_list
    authorize(@message_draft_template, policy_class: MessageDraftTemplatePolicy)

    @recipients_list = @message_draft_template.recipients
  end

  private

  def load_message_draft_template
    @message_draft_template = MessageDraftTemplate.find(params[:message_draft_template_id])
  end
end
