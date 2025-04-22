class Fs::ValidateMessageDraftResultJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  after_discard do
    GoodJob::Job.find_by(active_job_id: job.job_id).destroy
  end

  def perform(_message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata[:status] = 'created'
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'invalid'
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end

    unless response[:body]['result'] == 'OK'
      message_draft.metadata[:validation_errors] = {
        result: response[:body]['result'],
        errors: response[:body]['problems']&.select { |problem| problem['level'] == 'error' }&.map{ |problem| problem['message'] },
        warnings: response[:body]['problems']&.select { |problem| problem['level'] == 'warning' }&.map{ |problem| problem['message'] },
      }

      diff = response[:body]['problems']&.select { |problem| problem['level'] == 'diff' }
      Rails.logger.info("Message draft DIFF: #{diff.map{ |problem| problem['message']}.join(', ')}") if diff.any?

      message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag) if message_draft.metadata[:validation_errors][:errors].any? || message_draft.metadata[:validation_errors][:warnings].any?
    end

    message_draft.save
  end
end
