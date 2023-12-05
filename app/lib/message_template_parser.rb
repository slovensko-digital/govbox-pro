module MessageTemplateParser
  PLACEHOLDER_PATTERN=/({{ ?([\p{L} +]+)(\*?):([\p{L}_]+)(?:\:"([\p{L}.@\-+_\d\s]+)")? }})/

  def self.parse_template_placeholders(template)
    template_content = template.content

    placeholders = []
    template_content.scan(PLACEHOLDER_PATTERN) do |placeholder, name, required, type, default_value|
      placeholders << {
        placeholder: placeholder,
        name: name,
        required: required.present?,
        type: type,
        default_value: default_value
      }
    end

    placeholders
  end
end
