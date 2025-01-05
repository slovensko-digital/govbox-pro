module Govbox
  class SyncFolderJob < ApplicationJob
    def perform(folder, upvs_client: UpvsEnvironment.upvs_client, batch_size: 1000)
      edesk_api = upvs_client.api(folder.box).edesk
      new_messages_ids = []

      sync_since = Date.parse(folder.box.settings['sync_since']) if folder.box.settings['sync_since'].present?
      sync_from_page = folder.settings['sync_from_page'] || 0
      sync_from_message_id = folder.settings['sync_from_message_id']

      sync_from_page.step do |k|
        response_status, raw_messages = edesk_api.fetch_messages(folder.edesk_folder_id, page: k + 1, count: batch_size)

        raise "Unable to fetch folder messages" if response_status != 200

        edesk_message_ids_to_folder_ids = Govbox::Message.joins(:folder).where(folder: { box_id: folder.box.id }).where(edesk_message_id: raw_messages.pluck('id')).pluck(:edesk_message_id, :folder_id).to_h
        moved_edesk_message_ids = []

        raw_messages.each do |raw_message|
          next if sync_since && (Date.parse(raw_message['delivered_at']) < sync_since)

          edesk_message_id = raw_message['id']

          raise "MessageID out of order!" if sync_from_message_id && edesk_message_id < sync_from_message_id

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
