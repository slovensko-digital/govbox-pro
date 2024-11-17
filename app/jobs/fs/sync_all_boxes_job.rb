module Fs
  class SyncAllBoxesJob < ApplicationJob
    def perform
      Fs::Box.where(syncable: true).find_each do |box|
        SyncBoxJob.perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('FS_SYNC')
    end
  end
end
