class Admin::Boxes::BoxFormComponent < ViewComponent::Base
  def initialize(box:, action:)
    @box = box
    @action = action
  end
end
