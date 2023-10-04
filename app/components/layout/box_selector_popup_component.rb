class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  def initialize(boxes, all_unread_messages_count)
    @boxes = boxes
    @all_unread_messages_count = all_unread_messages_count
  end
end
