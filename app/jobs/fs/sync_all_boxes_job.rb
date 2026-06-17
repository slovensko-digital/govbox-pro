module Fs
  class SyncAllBoxesJob < ApplicationJob
    def perform
      wait = 0
      api_connections_to_sync.find_each do |api_connection|
        SyncApiConnectionJob.set(wait: wait.seconds).perform_later(api_connection)
        wait += api_connection.boxes.count
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
