module ApplicationHelper
  def nice_datetime(datetime)
    if datetime.today?
      l(datetime, format: '%H:%M')
    elsif datetime.year == Date.current.year
      l(datetime, format: '%e. %b')
    else
      l(datetime, format: '%e. %b %Y')
    end
  end

  def nice_datetime_with_time(datetime)
    if datetime.today?
      l(datetime, format: '%H:%M')
    elsif datetime.year == Date.current.year
      l(datetime, format: '%e. %b %H:%M')
    else
      l(datetime, format: '%e. %b %Y %H:%M')
    end
  end

  def to_icon_name(thing)
    case thing
    when Notifications::NewMessageThread
      "envelope"
    when Notifications::NewMessage
      "chat-bubble-left-right"
    when Notifications::MessageThreadNoteChanged
      "pencil-square"
    end
  end
end
