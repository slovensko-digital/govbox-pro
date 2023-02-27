class Submissions::SubmitPackageJob < ApplicationJob
  queue_as :high_priority

  def perform(package, submit_job: Submissions::SubmitJob)
    package.submissions.each do |submission|
      submit_job.new.perform(submission)
      # submit_job.perform_later(submission)
    end
  end
end
