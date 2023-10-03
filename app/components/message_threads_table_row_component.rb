class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
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
