class MessageTemplatesController < ApplicationController
  before_action :load_message_template

  def recipients_list
    authorize(@message_template, policy_class: MessageTemplatePolicy)

    @recipients_list = @message_template.recipients
  end

  private

  def load_message_template
    @message_template = MessageTemplate.find(params[:message_template_id])
  end
end
