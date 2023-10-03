class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:, search_highlight: nil)
    @message_thread = message_thread
    @search_highlight = search_highlight
  end

  def shorten_datetime(datetime)
    if datetime.today?
      l(datetime, format: "%e. %b %H:%I")
    elsif datetime.year == Date.current.year
      l(datetime, format: "%e. %b")
    else
      l(datetime, format: "%e. %b %Y")
    end
  end
end
