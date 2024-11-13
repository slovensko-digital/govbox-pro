class FormatFsMessagesHtmlVisualizations < ActiveRecord::Migration[7.1]
  include ActionView::Helpers::TextHelper

  def up
    Fs::MessageDraft.find_each do |message_draft|
      message_draft.update(html_visualization: simple_format(message_draft.html_visualization))
    end
  end
end
