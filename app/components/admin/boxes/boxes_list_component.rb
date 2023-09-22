class Admin::Boxes::BoxesListComponent < ViewComponent::Base
  def initialize(boxes)
    @boxes = boxes
  end
end
