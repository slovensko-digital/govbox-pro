module DiscardOnDeserializationError
  extend ActiveSupport::Concern

  included do
    discard_on ActiveJob::DeserializationError

    after_discard do |job, exception|
      return unless exception.is_a?(ActiveJob::DeserializationError)

      Rails.logger.warn("Deleting job #{job.job_id} due to #{exception.message}")
      GoodJob::Job.find_by(active_job_id: job.job_id).destroy
    end
  end
end
