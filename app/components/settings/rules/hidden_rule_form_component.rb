class Settings::Rules::HiddenRuleFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
end
