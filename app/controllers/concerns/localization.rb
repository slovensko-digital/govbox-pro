module Localization
  extend ActiveSupport::Concern

  included do
    before_action :set_sk_locale
  end

  def set_en_locale
    I18n.locale = :en
  end

  def set_sk_locale
    I18n.locale = :sk
  end
end
