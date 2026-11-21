class RegexpValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    Regexp.new(value) if value.present?
  rescue RegexpError => e
    record.errors.add(attribute, :invalid_regexp, message: "is not a valid regular expression (#{e.message})")
  end
end
