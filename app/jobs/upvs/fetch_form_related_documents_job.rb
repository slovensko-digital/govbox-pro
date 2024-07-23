module Upvs
  class FetchFormRelatedDocumentsJob < ApplicationJob
    queue_as :default

    DEFAULT_JOB_PRIORITY = 1000

    def perform(download_job: DownloadFormRelatedDocumentsJob, priority: DEFAULT_JOB_PRIORITY)
      Upvs::Form.find_each do |upvs_form|
        download_job.set(priority: priority).perform_later(upvs_form)
      end
    end
  end
end
