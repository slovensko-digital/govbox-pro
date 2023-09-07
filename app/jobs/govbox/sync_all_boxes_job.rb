module Govbox
  class SyncAllBoxesJob < ApplicationJob
    queue_as :default

    def perform
      Box.find_each do |box|
        SyncBoxJob.perform_later(box) if box.syncable?
      end
    end
  end
end
