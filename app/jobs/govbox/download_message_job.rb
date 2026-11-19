module Govbox
  class DownloadMessageJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_concurrency_rule(
      label: -> { "Govbox::DownloadMessageJob-#{arguments.first.try(:box_id)}-#{arguments.second}" },
      apply_label: true,
      total_limit: 1
    )

    def perform(govbox_folder, edesk_message_id, upvs_client: UpvsEnvironment.upvs_client)
      edesk_api = upvs_client.api(govbox_folder.box).edesk
      response_status, raw_message = edesk_api.fetch_message(edesk_message_id)

      raise "Unable to fetch message: #{response_status} #{raw_message.to_s.truncate(500)}" if response_status != 200

      govbox_message = govbox_folder.messages.find_or_create_by!(
        edesk_message_id: raw_message["id"]
      ) do |govbox_message|
        govbox_message.message_id = raw_message["message_id"]
        govbox_message.correlation_id = raw_message["correlation_id"]
        govbox_message.delivered_at = Time.parse(raw_message["delivered_at"])
        govbox_message.edesk_class = raw_message["class"]
        govbox_message.payload = raw_message
      end

      ProcessMessageJob.perform_later(govbox_message)
    end
  end
end
