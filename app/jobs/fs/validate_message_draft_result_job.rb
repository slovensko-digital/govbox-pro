class Fs::ValidateMessageDraftResultJob < ApplicationJob
  include DiscardOnDeserializationError

  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata[:status] = 'created'
    elsif [400, 422].include?(response[:status])
      mark_message_draft_invalid(message_draft)
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

    mark_message_draft_invalid(message_draft) if errors.any?

    message_draft.metadata[:validation_errors] = {
      result: result,
      errors: errors,
      warnings: warnings,
      diff: diff
    }

    # TODO log occurence if diff.any?

    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag) if errors.any? || warnings.any?

    if message_draft.metadata[:status] == 'created' && errors.none? && message_draft.form.signature_required && !message_draft.form_object.is_signed?
      signature_target = message_draft.signature_target_group

      signature_target.signature_requested_from_tag&.assign_to_message_object(message_draft.form_object)
      signature_target.signature_requested_from_tag&.assign_to_thread(message_draft.thread)
    end

    message_draft.save
    EventBus.publish(:message_draft_validated, message_draft)
  end

  private

  def mark_message_draft_invalid(message_draft)
    message_draft.metadata[:status] = 'invalid'
    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
  end
end
