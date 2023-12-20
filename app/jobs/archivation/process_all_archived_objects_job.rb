class Archivation::ProcessAllArchivedObjectsJob < ApplicationJob
  def perform
    MessageThread.all.select(&:archived?).each do |message_thread|
      Archivation::ProcessMessageThreadJob.perform_later(message_thread)
    end
  end
end
