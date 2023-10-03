class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:, search_highlight: nil)
    @message_thread = message_thread
    @search_highlight = search_highlight
  end
end
