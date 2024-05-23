module Govbox
  class SyncFolderJob < ApplicationJob
    queue_as :default

    def perform(folder, upvs_client: UpvsEnvironment.upvs_client, batch_size: 1000)
      edesk_api = upvs_client.api(folder.box).edesk
      new_messages_ids = []

      0.step do |k|
        response_status, raw_messages = edesk_api.fetch_messages(folder.edesk_folder_id, page: k + 1, count: batch_size)

        raise "Unable to fetch folder messages" if response_status != 200

        edesk_message_ids_to_folder_ids = Govbox::Message.joins(:folder).where(folder: { box_id: folder.box.id }).where(edesk_message_id: raw_messages.pluck('id')).pluck(:edesk_message_id, :folder_id).to_h
        moved_edesk_message_ids = []

        raw_messages.each do |raw_message|
          edesk_message_id = raw_message['id']
          old_folder_id = edesk_message_ids_to_folder_ids[edesk_message_id]

          if old_folder_id.nil?
            new_messages_ids << edesk_message_id
          elsif old_folder_id != folder.id
            moved_edesk_message_ids << edesk_message_id
          end
        end

        if moved_edesk_message_ids.any?
          # TODO: change tag
          Govbox::Message.where(edesk_message_id: moved_edesk_message_ids).update_all(folder_id: folder.id)
        end

        break if raw_messages.size < batch_size
      end

      new_messages_ids.each do |edesk_message_id|
        DownloadMessageJob.perform_later(folder, edesk_message_id)
      end
    end
  end
end
