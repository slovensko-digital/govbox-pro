class Admin::Boxes::BoxFormComponent < ViewComponent::Base
  def initialize(box:, action:)
    @box = box
    @action = action
    @color_select_options = Box.colors.keys.map { |color| [color, { class: "bg-#{color}-100 text-#{color}-600" }] }
  end
end
