class UpdateMessagesHtmlVisualization < ActiveRecord::Migration[7.1]
  def change
    Message.find_each do |message|
      next unless message.html_visualization.present?

      message.update_html_visualization
    end
  end
end
