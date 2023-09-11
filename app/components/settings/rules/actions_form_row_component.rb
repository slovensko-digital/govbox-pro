class Settings::Rules::ActionsFormRowComponent < ViewComponent::Base
  def initialize(form:, index:, editable: true)
    @form = form
    @index = index
    @editable = editable
  end
end