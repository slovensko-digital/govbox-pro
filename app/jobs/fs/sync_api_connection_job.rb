module Fs
  class SyncApiConnectionJob < ApplicationJob
    retry_on StandardError, attempts: 3

    def perform(api_connection, from: Date.yesterday, to: Date.tomorrow, fs_client: FsEnvironment.fs_client, batch_size: 25)
      first_box, *remaining_boxes = eligible_boxes(api_connection).to_a
      return unless first_box

      SyncBoxJob.new.perform(
        first_box,
        api_connection: api_connection,
        from: from,
        to: to,
        fs_client: fs_client,
        batch_size: batch_size
      )

      remaining_boxes.each_with_index do |box, index|
        SyncBoxJob.set(wait: index.seconds).perform_later(
          box,
          api_connection: api_connection,
          from: from,
          to: to,
          batch_size: batch_size
        )
      end
    rescue Fs::AuthenticationError
      api_connection.mark_authentication_failed!
      Rails.logger.info("Skipping FS sync for api_connection_id=#{api_connection.id} after authentication failure")
    end

    private

    def eligible_boxes(api_connection)
      Fs::Box
        .joins(:boxes_api_connections)
        .merge(BoxesApiConnection.active.where(api_connection: api_connection))
        .active
        .syncable
        .distinct
        .order(:id)
    end
  end
end
