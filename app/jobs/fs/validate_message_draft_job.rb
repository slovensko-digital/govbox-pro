class Fs::ValidateMessageDraftJob < ApplicationJob
  include DiscardOnDeserializationError
  include GoodJob::ActiveJobExtensions::Concurrency

  class ValidationError < StandardError
  end

  class TemporaryValidationError < ValidationError
  end


  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 1,

    key: -> { "Fs::ValidateMessageDraftJob-#{arguments.first.try(:id)}" }
  )

  retry_on TemporaryValidationError, wait: 2.minutes, attempts: 5

  retry_on ValidationError, attempts: 1 do |_job, _error|
    # no-op
  end

  def perform(message_draft, fs_client: FsEnvironment.fs_client)
    message_draft.metadata['status'] = 'being_validated'
    message_draft.save

    response = fs_client.api(box: message_draft.thread.box).post_validation(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content),
      message_draft.attachments.map do |attachment|
        {
          mime_type: attachment.mimetype,
          identifier: attachment.identifier
        }
      end
    )

    handle_validation_fail(message_draft, response[:status], response[:body]) unless response[:status] == 202

    Fs::ValidateMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end

  private

  def handle_validation_fail(message_draft, response_status, response_body)
    case response_status
    when 408, 503
      raise TemporaryValidationError, error_message(message_draft, response_status, response_body)
    else
      mark_message_draft_invalid(message_draft)
      raise ValidationError, error_message(message_draft, response_status, response_body)
    end
  end

  def error_message(message_draft, response_status, response_body)
    "Box #{message_draft.box.id}, Message #{message_draft.uuid}: #{response_status}, #{response_body}"
  end

  def mark_message_draft_invalid(message_draft)
    # TODO notification
    message_draft.metadata[:status] = 'invalid'
    message_draft.save
    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
  end
end
