module Fs
  class BoxifyApiConnectionJob < ApplicationJob
    def perform(api_connection)
      Box.transaction do
        api_connection.boxify
      end
    end
  end
end
