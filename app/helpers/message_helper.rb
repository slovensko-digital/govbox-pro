module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def self.html_visualization_for_display(message)
    return CGI.escapeHTML(message.html_visualization.to_s) if message.built_from_template?
    return message.html_visualization unless message.box.is_a?(Fs::Box)

    # FS forms hide these with their own JavaScript, which never runs in the visualization iframe.
    "<style>noscript, #buttonsPlaceholder, #statusDialog { display: none; }</style>#{message.html_visualization}"
  end
end
