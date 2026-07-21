class Fs::ValidateMessageDraftResultJob < ApplicationJob
  include DiscardOnDeserializationError

  WARNING_LEVELS = ['warning', 'warning section-error'].freeze
  DIFF_LEVELS = ['diff', 'diff_warning', 'diff_error'].freeze

  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata['status'] = 'created'
    elsif [400, 422].include?(response[:status])
      message_draft.mark_as_invalid
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end

    problems = response[:body]['problems'] || []

    warnings      = messages_for(problems, *WARNING_LEVELS)
    diff_warnings = messages_for(problems, 'diff_warning')
    diff_errors   = messages_for(problems, 'diff_error')
    diff          = messages_for(problems, 'diff')
    errors        = problems.reject { |problem| problem['level'].in?(WARNING_LEVELS + DIFF_LEVELS) }.map { |problem| problem['message'] }

    result = if errors.none? && warnings.none? && diff_errors.none? && diff_warnings.none? && diff.any?
               'OK'
             else
               response[:body]['result']
             end

    message_draft.metadata['validation_errors'] = {
      'result'        => result,
      'errors'        => errors,
      'warnings'      => warnings,
      'diff_warnings' => diff_warnings,
      'diff_errors'   => diff_errors,
      'diff'          => diff,
      'corrected_xml' => response[:body]['corrected_xml']
    }

    message_draft.validate_and_process

    EventBus.publish(:message_draft_validated, message_draft)
  end

  private

  def messages_for(problems, *levels)
    problems.select { |problem| problem['level'].in?(levels) }.map { |problem| problem['message'] }
  end
end
