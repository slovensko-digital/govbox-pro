module Govbox
  class DownloadMessageJob < ApplicationJob
    queue_as :default

    def perform(folder, edesk_message_id, upvs_client: UpvsEnvironment.upvs_client)
      edesk_api = upvs_client.api(folder.box).edesk
      response_status, raw_message = edesk_api.fetch_message(edesk_message_id)

      raise "Unable to fetch folder messages" if response_status != 200

      govbox_message = folder.messages.create!(
        edesk_message_id: raw_message["id"],
        message_id: raw_message["message_id"],
        correlation_id: raw_message["correlation_id"],
        delivered_at: Time.parse(raw_message["delivered_at"]),
        edesk_class: raw_message["class"],
        body: raw_message["original_xml"]
      )

      ProcessMessageJob.perform_later(govbox_message)
    end
  end
end
