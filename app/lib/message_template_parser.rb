module MessageTemplateParser
  PLACEHOLDER_PATTERN = /({{([a-zA-Z\u00C0-\u017F\s]+):([a-zA-Z\u00C0-\u017F0-9.+@\s]+)*:(\*)?(\w*)}})/

  def self.parse_template_placeholders(template)
    template_content = template.content

    placeholders = []
    template_content.scan(PLACEHOLDER_PATTERN) do |placeholder, name, default_value, required, type|
      placeholders << {
        placeholder: placeholder,
        name: name,
        default_value: default_value,
        required: required.present?,
        type: type
      }
    end

    placeholders
  end
end
