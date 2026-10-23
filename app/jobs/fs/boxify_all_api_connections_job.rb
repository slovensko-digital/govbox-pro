module Fs
  class BoxifyAllApiConnectionsJob < ApplicationJob
    def perform
      Fs::ApiConnection.joins(:tenant).merge(Tenant.active).find_each do |api_connection|
        next unless api_connection.settings.present?

        Fs::BoxifyApiConnectionJob.perform_later(api_connection)
      end
    end
  end
end
