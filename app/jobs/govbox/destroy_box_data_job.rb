module Govbox
  class DestroyBoxDataJob < ApplicationJob
    def perform(box_id)
      Govbox::Folder.where(box_id: box_id).find_each { |govbox_folder| govbox_folder.messages.in_batches(of: 50).destroy_all }
      Govbox::Folder.where(box_id: box_id).destroy_all
    end
  end
end
