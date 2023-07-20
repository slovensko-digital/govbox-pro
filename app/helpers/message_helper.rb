module MessageHelper
  include Rails.application.routes.url_helpers

  def self.message_link(message)
    if message.is_a?(DraftMessage)
      Rails.application.routes.url_helpers.draft_message_path(message)
    else
      Rails.application.routes.url_helpers.message_path(message)
    end
  end
end
