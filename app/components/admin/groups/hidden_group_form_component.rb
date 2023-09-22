class Admin::Groups::HiddenGroupFormComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end
end
