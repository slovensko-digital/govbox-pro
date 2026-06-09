module Fs
  class SyncAllBoxesJob < ApplicationJob
    def perform
      api_connections_to_sync.find_each.with_index do |api_connection, index|
        SyncApiConnectionJob.set(wait: index.seconds).perform_later(api_connection)
      end

      BetterUptimeApi.ping_heartbeat('FS_SYNC')
    end

    private

    def api_connections_to_sync
      Fs::ApiConnection.joins(boxes_api_connections: :box)
                       .merge(BoxesApiConnection.active)
                       .merge(Fs::Box.active.syncable)
                       .distinct
    end
  end
end
