class Icons::InfoComponent < ViewComponent::Base
  def initialize(css_classes: nil, stroke_width: 1.5)
    @css_classes = css_classes
    @stroke_width = stroke_width
  end

  def self.big_gray
    new(css_classes: "w-8 h-8 text-gray-400")
  end
end
