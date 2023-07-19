class Govbox::SubmitMessageReplyJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message_reply, upvs_client: UpvsEnvironment.upvs_client)
    reply_data = {
      message_id: message_reply.uuid,
      correlation_id: message_reply.metadata["correlation_id"],
      reference_id: message_reply.metadata["uuid"],
      recipient_uri: message_reply.metadata["recipient_uri"],
      general_agenda: {
        subject: message_reply.title,
        body: message_reply.metadata["body"]
      }
    }

    sktalk_api = upvs_client.api(message.thread.folder.box).sktalk

    success, response_status = sktalk_api.receive_and_save_to_outbox(reply_data)

    raise StandardError "Message reply submission failed!" unless success

    Govbox::SyncBoxJob.set(wait: 2.minutes).perform_later(message.thread.folder.box)
  end

  delegate :uuid, to: self
end
