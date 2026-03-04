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

  def nice_datetime_with_time(datetime, full_date: false)
    if datetime.today? && !full_date
      l(datetime, format: '%H:%M')
    elsif datetime.year == Date.current.year && !full_date
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
    when Notifications::ExportStarted
      "folder"
    when Notifications::ExportFinished
      "folder-arrow-down"
    end
  end

  def sort_tags(tags)
    tags.sort_by(&:name).sort_by { |i| i.type.in?(%w[ValidationWarningTag ValidationErrorTag ProblemTag SubmissionErrorTag UnprocessableTag]) ? 1 : 0 }
  end
end
