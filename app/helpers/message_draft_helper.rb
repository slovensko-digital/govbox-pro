module MessageDraftHelper
  def self.body_tag_id(message_draft)
    "message_#{message_draft.id}_body"
  end

  def self.attachments_tag_id(message_draft)
    "message_#{message_draft.id}_attachments"
  end

  def self.title_tag_id(message_draft)
    "message_#{message_draft.id}_title"
  end

  def self.text_tag_id(message_draft)
    "message_#{message_draft.id}_text"
  end
end
