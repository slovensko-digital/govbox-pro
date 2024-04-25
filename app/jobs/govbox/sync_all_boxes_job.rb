module Govbox
  class SyncAllBoxesJob < ApplicationJob
    queue_as :default

    def perform
      Box.where(syncable: true).find_each do |box|
        SyncBoxJob.perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('GBPRO_BOX_SYNC')
    end
  end
end
