class Layout::BoxListComponent < ViewComponent::Base
  with_collection_parameter :box

  def initialize(box:)
    @box = box
  end
end
