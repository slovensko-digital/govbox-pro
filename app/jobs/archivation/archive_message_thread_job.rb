class Archivation::ArchiveMessageThreadJob < ApplicationJob
  def perform(message_thread)
    message_thread.messages.each do |message|
      Archivation::ArchiveMessageJob.perform_later(message)
    end
  end
end
