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

  def full_datetime(datetime)
    l(datetime, format: '%Y-%m-%e %H:%M:%S')
  end
end
