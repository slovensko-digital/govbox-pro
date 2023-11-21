class Icons::ChevronDownComponent < ViewComponent::Base
  def initialize(css_classes: nil, stroke_width: 1.5)
    @css_classes = css_classes
    @stroke_width = stroke_width
  end

  def self.gray
    new(css_classes: "w-6 h-6 text-gray-500")
  end
end
