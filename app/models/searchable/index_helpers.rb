module Searchable::IndexHelpers
  extend self

  BODY_REGEXP = /<body[^>]*>(.*?)<\/body>/im

  def html_to_searchable_string(html)
    return html unless html

    body = html.match(BODY_REGEXP)[1]

    create_single_line_string(
      transliterate(
        remove_html_tags(
          add_spaces_between_tags(body)
        )
      )
    )
  end

  def searchable_string(string)
    return string unless string

    create_single_line_string(transliterate(string))
  end

  private

  def add_spaces_between_tags(html_string)
    html_string.gsub(/<\/([^>]*)><([^>]*)>/, '</\1> <\2>')
  end

  def remove_html_tags(html)
    ActionView::Base.full_sanitizer.sanitize(html)
  end

  def create_single_line_string(string)
    # non breakable space, new lines, duplicate spaces
    string.gsub("\u00A0", '').gsub(/\R+/, ' ').gsub(/\s+/, ' ').strip
  end

  def transliterate(str)
    return str unless str

    str.tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšȘșſŢţŤťŦŧȚțÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
           "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSsSssTtTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
  end
end
