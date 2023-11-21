# TODO fix a domain way to handle this (without n+1 query)
module Attachments
  def signable_attachment?
    @message.draft? && @message_attachment.not_signed?
  end

  def destroyable_attachment?
    @message.draft? && @message.not_yet_submitted? && @message_attachment.not_form?
  end
end
