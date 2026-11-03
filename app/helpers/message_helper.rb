module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def self.html_visualization_for_display(message)
    return CGI.escapeHTML(message.html_visualization.to_s) if message.built_from_template?

    message.prepare_html_visualization_for_display
  end
end
