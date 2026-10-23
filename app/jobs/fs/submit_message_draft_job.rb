class Fs::SubmitMessageDraftJob < ApplicationJob
  class SubmissionError < StandardError
  end

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_concurrency_rule(
    label: -> { "Fs::SubmitMessageDraftJob-#{arguments.first.try(:id)}" },
    apply_label: true,
    total_limit: 1
  )

  retry_on SubmissionError, attempts: 1 do |_job, _error|
    # no-op
  end

  def perform(message_draft, bulk_submit: false, fs_client: FsEnvironment.fs_client)
    raise "Invalid message!" unless message_draft.valid?(:validate_data)

    begin
      fs_api = fs_client.api(box: message_draft.box, api_connection: message_draft.find_api_connection_for_submission)
    rescue Exception => e
      handle_submit_fail(message_draft, e.message)
    end

    response = fs_api.post_submission(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content),
      message_uuid: message_draft.uuid,
      form_object_uuid: message_draft.form_object.uuid,
      allow_warn_status: true,
      is_signed: message_draft.form_object.is_signed,
      mime_type: message_draft.form_object.mimetype,
      attachments: message_draft.attachments.map do |attachment|
        {
          mime_type: Utils.to_fs_mimetype(attachment.mimetype),
          content: Base64.strict_encode64(attachment.content),
          object_id: attachment.uuid,
          identifier: attachment.identifier
        }
      end
    )

    message_draft.thread.box.message_submission_requests.create(
      request_url: fs_api.submission_url,
      response_status: response[:status],
      bulk: bulk_submit
    )

    handle_submit_fail(message_draft, "Response status is not 202. Message #{response[:body][:errors]}", expose_error: false) unless response[:status] == 202

    Fs::SubmitMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end

  private

  def handle_submit_fail(message_draft, error_message, expose_error: true)
    message_draft.metadata['submit_error_message'] = error_message if expose_error
    message_draft.submit_failed!

    raise SubmissionError, error_message
  end
end
