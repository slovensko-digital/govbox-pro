module MessageObjectHelper
  def self.displayable_name(message_object)
    message_object.name.present? ? message_object.name : I18n.t('no_message_object_name') + Utils.file_extension_by_mime_type(message_object.mimetype).to_s
  end

  def self.pdf_name(message_object)
    self.base_name(message_object) + '.pdf'
  end

  def self.base_name(message_object)
    message_object.name.present? ? File.basename(message_object.name, File.extname(message_object.name)) : I18n.t('no_message_object_name')
  end
end
