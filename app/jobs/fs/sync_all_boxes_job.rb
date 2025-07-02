module Fs
  class SyncAllBoxesJob < ApplicationJob
    def perform
      Fs::Box.where(syncable: true).find_each.with_index do |box, index|
        SyncBoxJob.set(wait: index*1.second).perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('FS_SYNC')
    end
  end
end
