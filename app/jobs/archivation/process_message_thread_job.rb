class Archivation::ProcessMessageThreadJob < ApplicationJob
  def perform(message_thread)
    message_thread.messages.each do |message|
      Archivation::ProcessMessageJob.perform_later(message)
    end
  end
end
