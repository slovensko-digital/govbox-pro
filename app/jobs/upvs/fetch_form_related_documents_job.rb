module Upvs
  class FetchFormRelatedDocumentsJob < ApplicationJob
    def perform(download_job: DownloadFormRelatedDocumentsJob)
      Upvs::Form.find_each do |upvs_form|
        download_job.set(queue: self.queue_name).perform_later(upvs_form)
      end
    end
  end
end
