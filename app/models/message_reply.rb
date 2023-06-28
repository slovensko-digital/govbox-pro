class MessageReply
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor(:title, :text)

  def valid?
    title.present? && text.present?
  end
end