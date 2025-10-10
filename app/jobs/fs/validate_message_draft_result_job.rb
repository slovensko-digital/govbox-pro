class Fs::ValidateMessageDraftResultJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  after_discard do |job, exception|
    return unless exception.is_a?(ActiveJob::DeserializationError)

    Rails.logger.warn("Deleting job #{job.job_id} due to #{exception.message}")
    GoodJob::Job.find_by(active_job_id: job.job_id).destroy
  end

  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata[:status] = 'created'
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'invalid'
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end

    errors = response[:body]['problems']&.select { |problem| problem['level'] == 'error' }&.map{ |problem| problem['message'] } || []
    warnings = response[:body]['problems']&.select { |problem| problem['level'] == 'warning' }&.map{ |problem| problem['message'] } || []
    diff = response[:body]['problems']&.select { |problem| problem['level'] == 'diff' }&.map{ |problem| problem['message'] } || []

    result = if errors.none? && warnings.none? && diff.any?
      'OK'
    else
      response[:body]['result']
    end

    message_draft.metadata[:validation_errors] = {
      result: result,
      errors: errors,
      warnings: warnings,
      diff: diff
    }

    # TODO log occurence if diff.any?

    message_draft.add_cascading_tag(message_draft.tenant.validation_error_tag) if errors.any?
    message_draft.add_cascading_tag(message_draft.tenant.validation_warning_tag) if warnings.any?
    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag) if errors.any? || warnings.any?

    message_draft.save
    EventBus.publish(:message_draft_validated, message_draft)
  end
end
