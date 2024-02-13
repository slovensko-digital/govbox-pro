class MessageTemplatesController < ApplicationController
  before_action :load_message_template

  def recipient_selector
    authorize(@message_template, policy_class: MessageTemplatePolicy)

    @recipients_list = @message_template.recipients.first(10)
                                        .pluck(:institution_name, :institution_uri)
                                        .map { |name, uri| { uri: uri, name: name }}
  end

  def recipients_list
    authorize(@message_template, policy_class: MessageTemplatePolicy)

    @recipients_list = @message_template.recipients.first(10)
                                        .pluck(:institution_name, :institution_uri)
                                        .map { |name, uri| { uri: uri, name: name }}
  end

  def search_recipients_list
    authorize(@message_template, policy_class: MessageTemplatePolicy)

    @recipients_list = @message_template.recipients
                                        .where('unaccent(institution_name) ILIKE unaccent(?) OR institution_uri ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
                                        .pluck(:institution_name, :institution_uri)
                                        .map { |name, uri| { uri: uri, name: name }}
  end

  def recipient_selected
    authorize(@message_template, policy_class: MessageTemplatePolicy)

    @recipient_name = params[:recipient_name]
    @recipient_uri = params[:recipient_uri]
  end

  private

  def load_message_template
    @message_template = MessageTemplate.find(params[:message_template_id])
  end
end
