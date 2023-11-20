class Icons::MagnifyingGlassComponent < ViewComponent::Base
  def initialize(css_classes: nil, stroke_width: 1.5)
    @css_classes = css_classes
    @stroke_width = stroke_width
  end

  def self.gray(size: nil)
    css_parts = ["text-gray-400"]

    css_parts <<
      case size
        when "4"
          "w-4 h-4"
        when "5"
          "w-5 h-5"
        else
          "w-6 h-6"
      end

    new(css_classes: css_parts.join(" "))
  end
end
