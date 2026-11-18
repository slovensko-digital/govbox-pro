module MessageObjectHelper
  def self.displayable_name(message_object)
    message_object.name.presence || (I18n.t('no_message_object_name') + Utils.file_extension_by_mimetype(message_object.mimetype).to_s)
  end

  def self.pdf_name(message_object)
    base_name(message_object) + '.pdf'
  end

  PDF_BUSY_MESSAGE = "PDF sa nepodarilo pripraviť včas, skúste to o chvíľu znova. Veľké formuláre si stiahnete aj cez hromadný export.".freeze
  PDF_TOO_LARGE_MESSAGE = "Formulár je na PDF príliš veľký, stiahnite si jeho originál.".freeze

  def self.base_name(message_object)
    message_object.name.present? ? File.basename(message_object.name, File.extname(message_object.name)) : I18n.t('no_message_object_name')
  end
end
