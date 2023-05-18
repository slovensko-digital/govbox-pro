module Govbox
  class SyncFolderJob < ApplicationJob
    queue_as :default

    def perform(box, folder_hash)
      message_headers = [] # TODO do syncing magic - fetch from API

      message_headers.each do |message_header|
        DownloadMessageJob.perform_later(box, folder_hash, message_header['message_id'])
      end
    end
  end
end
