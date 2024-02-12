module Govbox
  class SyncBoxJob < ApplicationJob
    queue_as :default

    def perform(box)
      return unless box.syncable?

      edesk_api = UpvsEnvironment.upvs_api(box).edesk
      response_status, raw_folders = edesk_api.fetch_folders

      raise "Unable to fetch folders" if response_status != 200

      raw_folders = raw_folders.index_by {|f| f["id"]}
      raw_folders.each_value do |folder_hash|
        folder = find_or_create_folder_with_parent(folder_hash, raw_folders, box)
        SyncFolderJob.perform_later(folder) unless folder.bin? || folder.drafts?
      end
    end

    private

    def find_or_create_folder_with_parent(folder_hash, folders, box)
      parent_folder = nil

      if folder_hash['parent_id']
        parent_folder = find_or_create_folder_with_parent(folders[folder_hash['parent_id']], folders, box)
      end

      folder = Govbox::Folder.find_or_initialize_by(edesk_folder_id: folder_hash['id'], box: box).tap do |f|
        f.edesk_folder_id = folder_hash['id']
        f.parent_folder = parent_folder
        f.name = folder_hash['name']
        f.system = folder_hash['system'] || false
        f.save!
      end

      folder
    end
  end
end
