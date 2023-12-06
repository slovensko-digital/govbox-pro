class Admin::Boxes::BoxFormComponent < ViewComponent::Base
  include ColorizedHelper

  def initialize(box:, action:)
    @box = box
    @action = action
  end
end
