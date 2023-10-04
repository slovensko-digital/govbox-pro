module ApplicationHelper
  def nice_datetime(datetime)
    if datetime.today?
      l(datetime, format: "%H:%I")
    elsif datetime.year == Date.current.year
      l(datetime, format: "%e. %b")
    else
      l(datetime, format: "%e. %b %Y")
    end
  end
end
