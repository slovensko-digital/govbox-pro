module Govbox
  class SyncAllBoxesJob < ApplicationJob
    queue_as :default

    def perform
      Box.where(syncable: true).find_each do |box|
        SyncBoxJob.perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('GOVBOX_SYNC')
    end
  end
end
