class UpdateMessagesHtmlVisualizationJob < ApplicationJob
  def perform(update_message_job: UpdateMessageHtmlVisualizationJob)
    Message.where(html_visualization: nil).find_each do |message|
      update_message_job.perform_later(message)
    end
  end
end
