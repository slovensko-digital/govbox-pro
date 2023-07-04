class MessageReply
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor(:message, :title, :text)

  validates_presence_of :message, :title, :text

  def save
    if valid?
      Govbox::SubmitMessageReplyJob.perform_later(message, title, text)
    else
      false
    end
  end
end
