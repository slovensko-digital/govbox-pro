module MessageHelper
  include Rails.application.routes.url_helpers

  def self.message_link(message)
    if message.is_a?(MessageReply)
      Rails.application.routes.url_helpers.message_reply_path(message.original_message, message)
    else
      Rails.application.routes.url_helpers.message_path(message)
    end
  end
end
