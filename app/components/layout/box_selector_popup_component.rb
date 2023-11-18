class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  def initialize(boxes)
    @boxes = boxes
    @all_unread_messages_count = boxes.to_a.sum(&:unread_messages_count)
  end
end
