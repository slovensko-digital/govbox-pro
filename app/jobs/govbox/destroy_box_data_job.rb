module Govbox
  class DestroyBoxDataJob < ApplicationJob
    queue_as :default

    def perform(box_id)
      Govbox::Folder.where(box_id: box_id).find_each { |govbox_folder| govbox_folder.messages.in_batches(of: 50).destroy_all }
    end
  end
end
