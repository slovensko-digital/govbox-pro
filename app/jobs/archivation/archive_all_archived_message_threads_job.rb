class Archivation::ArchiveAllArchivedMessageThreadsJob < ApplicationJob
  def perform
    MessageThread.all.select(&:archived?).each do |message_thread|
      Archivation::ArchiveMessageThreadJob.perform_later(message_thread)
    end
  end
end
