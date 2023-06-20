module Govbox
  class SyncBoxJob < ApplicationJob
    queue_as :default

    def perform(box, upvs_client: UpvsEnvironment.upvs_client)
      edesk_api = upvs_client.api(box).edesk
      response_status, folders = edesk_api.fetch_folders

      raise "Unable to fetch folders" if response_status != 200

      folders.each do |folder_hash|
        Govbox::Folder.find_or_initialize_by(edesk_folder_id: folder_hash['id']).tap do |f|
          f.edesk_folder_id = folder_hash['id']
          f.name = folder_hash['name']
          f.system = folder_hash['system'] || false
          f.box = box
          f.save!
        end
      end

      folders.each do |folder_hash|
        folder = Govbox::Folder.find_or_initialize_by(edesk_folder_id: folder_hash['id'])
        folder.update!(
          parent_folder_id: Govbox::Folder.find_by(edesk_folder_id: folder_hash['parent_id'])&.id
        )

        SyncFolderJob.perform_later(folder)
      end
    end
  end
end
