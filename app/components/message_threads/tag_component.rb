module MessageThreads
  class TagComponent < ViewComponent::Base
    def initialize(message_thread_tag)
      @message_thread_tag = message_thread_tag
      @tag = @message_thread_tag.tag
    end
  end
end
