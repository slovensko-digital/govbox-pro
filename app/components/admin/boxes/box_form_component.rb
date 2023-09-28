class Admin::Boxes::BoxFormComponent < ViewComponent::Base
  def initialize(box:, action:)
    @box = box
    @action = action
    @color_select_options = Box.colors.map { |color| [color[0], { class:"bg-#{color[0]}-100 text-#{color[0]}-600" }] }
  end
end
