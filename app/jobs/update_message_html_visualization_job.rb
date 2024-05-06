class UpdateMessageHtmlVisualizationJob < ApplicationJob
  def perform(message)
    message.update_html_visualization
  end
end
