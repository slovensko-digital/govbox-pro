class Fs::ValidateMessageDraftResultJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      # TODO validation success
      puts "OK"
    elsif [400, 422].include?(response[:status])
      # TODO validation fail
      puts "FAIL"
      puts response[:body]
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end
  end
end
