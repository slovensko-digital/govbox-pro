module Govbox
  class DestroyBoxDataJob < ApplicationJob
    queue_as :default

    def perform(box_id, api_connection_id)
      Govbox::Folder.where(box_id: box_id).find_each { |govbox_folder| govbox_folder.messages.in_batches(of: 50).destroy_all }

      unless Box.where(api_connection_id: api_connection_id).exists?
        api_connection = ApiConnection.find(api_connection_id)
        api_connection.destroy if api_connection.is_a?(Govbox::ApiConnection)
      end
    end
  end
end
