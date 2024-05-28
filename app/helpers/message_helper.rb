module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def self.format_html_visualization(message)
    return ActionController::Base.helpers.simple_format(message.html_visualization) if message.is_a?(Fs::MessageDraft)

    message.html_visualization
  end
end
