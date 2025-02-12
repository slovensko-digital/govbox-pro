module MessageObjectHelper
  def self.displayable_name(message_object)
    message_object.name.present? ? message_object.name : I18n.t('no_message_object_name') + Utils.file_extension_by_mimetype(message_object.mimetype).to_s
  end

  def self.pdf_name(message_object)
    self.base_name(message_object) + '.pdf'
  end

  def self.base_name(message_object)
    message_object.name.present? ? File.basename(message_object.name, File.extname(message_object.name)) : I18n.t('no_message_object_name')
  end

  def self.unique_name_within_message(message_object, other_file_names, pdf: false)
    file_name = self.base_name(message_object)
    matches_count = other_file_names.count { |name| /#{file_name}( \(\d+\))?\.\w*/ =~ name }

    file_name += " (#{matches_count})" if matches_count > 0

    file_name + (pdf ? '.pdf' : File.extname(message_object.name))
  end
end
