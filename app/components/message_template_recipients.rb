class MessageTemplateRecipients < ViewComponent::Base
  def initialize(recipients_list:)
    @recipients_list = recipients_list
  end
end
