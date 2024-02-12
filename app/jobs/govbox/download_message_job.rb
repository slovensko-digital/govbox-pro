module Govbox
  class DownloadMessageJob < ApplicationJob
    queue_as :default

    def perform(govbox_folder, edesk_message_id)
      edesk_api = UpvsEnvironment.upvs_api(govbox_folder.box).edesk
      response_status, raw_message = edesk_api.fetch_message(edesk_message_id)

      raise "Unable to fetch folder messages" if response_status != 200

      govbox_message = govbox_folder.messages.find_or_create_by!(
        edesk_message_id: raw_message["id"]
      ) do |govbox_message|
        govbox_message.message_id = raw_message["message_id"]
        govbox_message.correlation_id = raw_message["correlation_id"]
        govbox_message.delivered_at = Time.parse(raw_message["delivered_at"])
        govbox_message.edesk_class = raw_message["class"]
        govbox_message.body = raw_message["original_xml"]
        govbox_message.payload = raw_message
      end

      ProcessMessageJob.perform_later(govbox_message)
    end
  end
end
