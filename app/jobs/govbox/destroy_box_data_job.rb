module Govbox
  class DestroyBoxDataJob < ApplicationJob
    queue_as :default

    def perform(box_id)
      Govbox::ApiConnection.find_by(box_id: box_id).destroy
      Govbox::Folder.where(box_id: box_id).destroy_all
    end
  end
end
