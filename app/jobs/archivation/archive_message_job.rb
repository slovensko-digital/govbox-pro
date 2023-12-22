class Archivation::ArchiveMessageJob < ApplicationJob
  def perform(message)
    message.objects.each do |message_object|
      Archivation::ArchiveMessageObjectJob.perform_later(message_object)
    end
  end
end
