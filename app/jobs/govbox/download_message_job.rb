module Govbox
  class DownloadMessageJob < ApplicationJob
    queue_as :default

    def perform(box, folder_hash, upvs_message_id)
      govbox_message = nil # TODO fetch from API based on id and save message somewhere to Govbox:: namespace temporarily
      ProcessMessageJob.perform_later(govbox_message)
    end
  end
end
