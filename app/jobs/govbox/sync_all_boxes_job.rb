module Govbox
  class SyncAllBoxesJob < ApplicationJob
    queue_as :default

    def perform
      Upvs::Box.where(syncable: true).find_each do |box|
        SyncBoxJob.perform_later(box)
      end
    end
  end
end
