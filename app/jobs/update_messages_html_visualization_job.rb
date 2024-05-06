class ReindexAndNotifyFilterSubscriptionsJob < ApplicationJob
  def perform
    Message.find_each do |message|
      next if message.html_visualization.present?

      message.update_html_visualization
    end
  end
end
