module Govbox
  class DestroyBoxDataJob < ApplicationJob
    queue_as :default

    def perform(box_id, api_connection_id)
      Govbox::Folder.where(box_id: box_id).find_each { |govbox_folder| govbox_folder.messages.in_batches(of: 50).destroy_all }

      if Box.where(api_connection_id: api_connection_id).count == 0
        ApiConnection.find(api_connection_id).destroy
      end
    end
  end
end
