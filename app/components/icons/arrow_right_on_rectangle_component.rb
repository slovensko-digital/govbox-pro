class Icons::ArrowRightOnRectangleComponent < ViewComponent::Base
  def initialize(css_classes: nil, stroke_width: 1.5)
    @css_classes = css_classes
    @stroke_width = stroke_width
  end
end
