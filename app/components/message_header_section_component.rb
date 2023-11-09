class MessageHeaderSectionComponent < ViewComponent::Base
  def initialize(label, value)
    @label = label
    @value = value
  end
end
