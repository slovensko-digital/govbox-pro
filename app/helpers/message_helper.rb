module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def self.html_visualization_for_display(message)
    return message.html_visualization unless message.built_from_template?

    CGI.escapeHTML(message.html_visualization.to_s)
  end
end
