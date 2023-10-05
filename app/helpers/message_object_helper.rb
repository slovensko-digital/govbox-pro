module MessageObjectHelper
  def self.displayable_name(message_object)
    message_object.name.present? ? message_object.name : I18n.t('no_message_object_name') + Utils.file_extension_by_mime_type(message_object.mimetype)
  end
end