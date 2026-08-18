class EscapeTemplateHtmlVisualizations < ActiveRecord::Migration[7.1]
  def change
    Message.where("metadata->>'template_id' IS NOT NULL").find_each do |message|
      next if message.metadata["data"].blank?

      message.update_columns(
        html_visualization: message.metadata["data"].map { _1.map { |value| ERB::Util.html_escape(value) }.join(": ") }.join(", ")
      )
    end
  end
end
