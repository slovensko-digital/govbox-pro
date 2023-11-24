module MessageDraftTemplateParser
  PLACEHOLDER_PATTERN = /({{(\w*):(\w*)}})/

  def self.parse_template_placeholders(template)
    template_content = template.content

    placeholders = []
    template_content.scan(PLACEHOLDER_PATTERN) do |placeholder, type, name|
      placeholders << {
        placeholder: placeholder,
        type: type,
        name: name
      }
    end

    placeholders
  end
end
