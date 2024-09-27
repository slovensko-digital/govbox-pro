module Govbox
  class SyncAllBoxesJob < ApplicationJob
    def perform
      Upvs::Box.where(syncable: true).find_each do |box|
        SyncBoxJob.perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('GOVBOX_SYNC')
    end
  end
end
