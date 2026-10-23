module Govbox
  class SyncAllBoxesJob < ApplicationJob
    def perform
      Upvs::Box.syncable.joins(:tenant).merge(Tenant.active).find_each do |box|
        SyncBoxJob.perform_later(box)
      end

      BetterUptimeApi.ping_heartbeat('GOVBOX_SYNC')
    end
  end
end
