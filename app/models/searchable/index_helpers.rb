module Searchable::IndexHelpers
  extend self

  BODY_PATTERN = %r{<body[^>]*>(.*?)</body>}im
  NON_SEARCHABLE_CSS = "head, script, style, noscript, template"

  def html_to_searchable_string(html)
    return html unless html

    searchable_string(extract_visible_text(html))
  end

  def searchable_string(string)
    return string unless string

    create_single_line_string(transliterate(string))
  end

  private

  def extract_visible_text(html)
    source_html = html.to_s.scrub
    source = source_html[BODY_PATTERN, 1] || source_html

    fragment = Nokogiri::HTML4::DocumentFragment.parse(source)
    fragment.css(NON_SEARCHABLE_CSS).remove
    fragment.text
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
