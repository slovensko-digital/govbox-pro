class Govbox::FinishMessageDraftsSubmitJob < ApplicationJob
  def perform(batch, params)
    Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(batch.properties[:box])
  end
end
