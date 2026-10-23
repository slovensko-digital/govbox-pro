class Archivation::ArchiveAllArchivedMessageThreadsJob < ApplicationJob
  def perform
    # TODO make this more effective - do not schedule all jobs every day
    MessageThread.joins(:tags, box: :tenant)
                 .where(tags: { type: ArchivedTag.to_s })
                 .merge(Tenant.active)
                 .find_each do |message_thread|
      Archivation::ArchiveMessageThreadJob.perform_later(message_thread)
    end
  end
end
