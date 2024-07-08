class Fs::ValidateMessageDraftResultJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata[:status] = 'created'
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'invalid'
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end

    message_draft.metadata[:validation_errors] = {
      result: response[:body]['result'],
      message: [response[:body]['message']]
    }
    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag) if message_draft.metadata[:validation_errors].present?
    message_draft.save
  end
end
