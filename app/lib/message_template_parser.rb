module MessageTemplateParser
  PLACEHOLDER_PATTERN = /({{([a-zA-Z\u00C0-\u017F\s]+):(\w*)}})/

  def self.parse_template_placeholders(template)
    template_content = template.content

    placeholders = []
    template_content.scan(PLACEHOLDER_PATTERN) do |placeholder, name, type|
      placeholders << {
        placeholder: placeholder,
        name: name,
        type: type
      }
    end

    placeholders
  end
end
