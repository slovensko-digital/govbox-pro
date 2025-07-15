class Fs::SubmitMessageDraftJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 1,

    key: -> { "Fs::SubmitMessageDraftJob-#{arguments.first.try(:id)}" }
  )

  def perform(message_draft, bulk_submit: false, fs_client: FsEnvironment.fs_client)
    raise "Invalid message!" unless message_draft.valid?(:validate_data)

    fs_api = fs_client.api(box: message_draft.box, api_connection: message_draft.find_api_connection_for_submission)

    response = fs_api.post_submission(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content),
      message_uuid: message_draft.uuid,
      form_object_uuid: message_draft.form_object.uuid,
      allow_warn_status: true,
      is_signed: message_draft.form_object.is_signed,
      mime_type: message_draft.form_object.mimetype
    )

    message_draft.thread.box.message_submission_requests.create(
      request_url: fs_api.submission_url,
      response_status: response[:status],
      bulk: bulk_submit
    )

    raise RuntimeError.new("Response status is not 202. Message #{response[:body][:errors]}") unless response[:status] == 202

    Fs::SubmitMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end
end
