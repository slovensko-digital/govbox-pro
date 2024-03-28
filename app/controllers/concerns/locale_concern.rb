module LocaleConcern
  def set_en_locale
    I18n.locale = :en
  end

  def set_sk_locale
    I18n.locale = :sk
  end
end
