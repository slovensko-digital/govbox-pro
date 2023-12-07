module Govbox
  class DownloadMessageJob < ApplicationJob
    queue_as :default

    def perform(edesk_message_id:, govbox_folder: nil, box: nil, upvs_client: UpvsEnvironment.upvs_client)
      setup_folder_and_box(box, govbox_folder)

      response_status, raw_message = upvs_client.api(@box).edesk.fetch_message(edesk_message_id)

      raise "Unable to fetch folder messages" if response_status != 200

      process_govbox_message(raw_message)
    end

    def setup_folder_and_box(box, govbox_folder)
      raise "Folder or Box must be specified" unless govbox_folder || box

      @box = box || govbox_folder.box
      @govbox_folder = govbox_folder || Govbox::Folder.where(box: box, name: 'Inbox')

      raise "Folder must match specified box" unless @govbox_folder.box == box
    end

    def process_govbox_message(raw_message)
      govbox_message = @govbox_folder.messages.create!(
        edesk_message_id: raw_message["id"],
        message_id: raw_message["message_id"],
        correlation_id: raw_message["correlation_id"],
        delivered_at: Time.parse(raw_message["delivered_at"]),
        edesk_class: raw_message["class"],
        body: raw_message["original_xml"],
        payload: raw_message
      )
      ProcessMessageJob.perform_later(govbox_message)
    end
  end
end
