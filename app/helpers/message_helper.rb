module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def format_html_visualization
    return ActionController::Base.helpers.simple_format(html_visualization) if is_a?(Fs::MessageDraft)

    html_visualization
  end
end
