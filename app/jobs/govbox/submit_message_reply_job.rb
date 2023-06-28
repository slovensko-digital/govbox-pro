class Govbox::SubmitMessageReplyJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message, reply_title, reply_text, upvs_client: UpvsEnvironment.upvs_client)
    reply_data = {
      message_id: uuid,
      correlation_id: message.metadata["correlation_id"],
      reference_id: message.uuid,
      recipient_uri: message.metadata["sender_uri"],
      general_agenda: {
        subject: reply_title,
        body: reply_text
      }
    }

    sktalk_api = upvs_client.api(message.thread.folder.box).sktalk

    success, response_status = sktalk_api.receive_and_save_to_outbox(reply_data)

    raise StandardError "Message reply submission failed!" unless success
  end

  delegate :uuid, to: self
end
