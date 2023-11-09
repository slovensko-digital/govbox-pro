class MessageHeaderSectionComponent < ViewComponent::Base
  def initialize(small_screen_label:, label:, value:)
    @small_screen_label = small_screen_label
    @label = label
    @value = value
  end
end
