class Settings::Rules::HiddenActionRowComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
end
