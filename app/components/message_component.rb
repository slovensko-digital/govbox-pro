class MessageComponent < ViewComponent::Base
  renders_many :attachments

  def initialize(message:, notice:, thread_tags_with_deletable_flag:)
    @message = message
    @notice = notice
    @thread_tags_with_deletable_flag = thread_tags_with_deletable_flag
  end
end
