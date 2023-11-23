class Govbox::ScheduleDelayedSyncBoxJob < ApplicationJob
  def perform(batch, params)
    batch.properties[:boxes].each { |box| Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(box) }
  end
end
