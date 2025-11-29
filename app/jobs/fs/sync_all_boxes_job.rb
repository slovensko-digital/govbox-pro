module Fs
  class SyncAllBoxesJob < ApplicationJob
    def perform
      Fs::Box.where(syncable: true, active: true).find_each.with_index do |box, index|
        box.boxes_api_connections.group_by(&:settings_delegate_id).each do |settings_delegate_id, boxes_api_connections|
          SyncBoxJob.set(wait: index*1.second).perform_later(box, api_connection: boxes_api_connections.first.api_connection)
        end
      end

      BetterUptimeApi.ping_heartbeat('FS_SYNC')
    end
  end
end
