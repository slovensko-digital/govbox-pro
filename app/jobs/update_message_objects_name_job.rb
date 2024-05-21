class UpdateMessageObjectsNameJob < ApplicationJob
  def perform
    MessageObject.find_each do |message_object|
      next unless message_object.name.present?

      UpdateMessageObjectNameJob.perform_later(message_object)
    end
  end
end
