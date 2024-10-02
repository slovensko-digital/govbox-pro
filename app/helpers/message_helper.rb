module MessageHelper
  def self.export_filename(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end

  def format_html_visualization
    return ActionController::Base.helpers.simple_format(html_visualization) if is_a?(Fs::MessageDraft)

    return metadata["data"].map do |k,v|
      "#{k}: #{v}"
    end.join(', ') if template.present?

    html_visualization
  end
end
