class Turbo::NewMessageChannel < Turbo::StreamsChannel
  def subscribed
    if authorized?
      stream_from stream_name
    else
      reject
    end
  end

  private

  def stream_name
    @stream_name ||= verified_stream_name_from_params
  end

  def authorized?
    return false unless connection.current_user

    gid = Base64.urlsafe_decode64(stream_name)
    message_thread = GlobalID::Locator.locate(gid)
    return false unless message_thread.is_a?(MessageThread)

    Pundit.policy_scope(connection.current_user, MessageThread).find(message_thread.id)
  end
end
