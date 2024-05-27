class Fs::SubmitMessageDraftResultJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.metadata[:status] = 'submitted'
      message_draft.save
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'submit_fail'
      message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
      message_draft.save
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end
  end
end
