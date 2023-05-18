module Govbox
  class SyncBoxJob < ApplicationJob
    queue_as :default

    def perform(box)
      folders = [] # TODO fetch from API

      folders.each do |folder_hash|
        SyncFolderJob.perform_later(box, folder_hash)
      end
    end
  end
end
