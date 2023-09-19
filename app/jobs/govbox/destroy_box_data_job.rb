module Govbox
  class DestroyBoxDataJob < ApplicationJob
    queue_as :default

    def perform(box)
      Govbox::ApiConnection.find_by(box_id: box.id).destroy
      Govbox::Folder.where(box_id: box.id).destroy_all
    end
  end
end
