module Govbox
  class DownloadMessageJob < ApplicationJob
    queue_as :default

    def perform(govbox_folder, edesk_message_id, upvs_client: UpvsEnvironment.upvs_client)
      edesk_api = upvs_client.api(govbox_folder.box).edesk
      response_status, raw_message = edesk_api.fetch_message(edesk_message_id)

      raise "Unable to fetch folder messages" if response_status != 200

      govbox_message = govbox_folder.messages.create!(
        edesk_message_id: raw_message["id"],
        message_id: raw_message["message_id"],
        correlation_id: raw_message["correlation_id"],
        delivered_at: Time.parse(raw_message["delivered_at"]),
        edesk_class: raw_message["class"],
        body: raw_message["original_xml"]
      )

      message = create_message(raw_message)

      MessageThread.transaction do
        Govbox::Message.create_message_thread!(govbox_message, message)
      end

      create_message_objects(message, raw_message)
    end

    private

    def create_message(raw_message)
      ::Message.create(
        uuid: raw_message["message_id"],
        title: raw_message["subject"],
        sender_name: raw_message["sender_name"],
        recipient_name: raw_message["recipient_name"],
        delivered_at: Time.parse(raw_message["delivered_at"])
      )
    end

    def create_message_objects(message, raw_message)
      raw_message["objects"].each do |raw_object|
        object = message.message_objects.create!(
          name: raw_object["name"],
          mimetype: raw_object["mime_type"],
          is_signed: raw_object["signed"],
          encoding: raw_object["encoding"],
          object_type: raw_object["class"]
        )

        MessageObjectDatum.create!(
          blob: raw_object["content"],
          message_object_id: object.id
        )
      end
    end
  end
end
