class Icons::StarComponent < ViewComponent::Base
  def initialize(css_classes: nil, stroke_width: 1.5, variant: :solid)
    @css_classes = css_classes
    @stroke_width = stroke_width
    @variant = variant
  end

  def solid?
    @variant == :solid
  end

  def light?
    @variant == :light
  end
end
