class Admin::Groups::GroupFormComponent < ViewComponent::Base
  def initialize(group:, readonly: false)
    @group = group
    @readonly = readonly
  end
end
