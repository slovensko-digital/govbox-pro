class Archivation::ArchiveAllArchivedMessageThreadsJob < ApplicationJob
  def perform
    MessageThread.joins(:tags).where(tags: {type: ArchivedTag.to_s}).find_each do |message_thread|
      Archivation::ArchiveMessageThreadJob.perform_later(message_thread)
    end
  end
end
