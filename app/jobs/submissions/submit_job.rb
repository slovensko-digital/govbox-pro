class Submissions::SubmitJob < ApplicationJob
  queue_as :high_priority

  def perform(submission, sender: GovboxApi)
    submission_data = {
      posp_id: submission.posp_id,
      posp_version: submission.posp_version,
      message_type: submission.message_type,
      message_id: submission.message_id,
      correlation_id: submission.correlation_id,
      recipient_uri: submission.recipient_uri,
      message_subject: submission.message_subject,
      objects: build_objects(submission)
    }

    sender = sender.new(submission.subject.sub)
    sender_response = sender.receive_and_save_to_outbox(submission_data)

    if sender_response
      Submission.update!(status: 'submitted')
    else
      raise "Submission #{submission.message_subject} failed!"
    end
  end

  private

  def build_objects(submission)
    objects = []
    submission.objects.each do |o|
      objects << {
        id: o.uuid,
        name: o.name,
        encoding: 'Base64',
        signed: o.signed,
        mime_type: o.mime_type,
        form: o.form,
        content: Base64.strict_encode64(o.content)
      }
    end

    objects
  end
end
