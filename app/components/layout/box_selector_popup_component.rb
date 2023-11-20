class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  FILTER_IF_NUMBER_OF_BOXES_ABOVE = 5

  def initialize(boxes_with_unread_message_counts)
    @boxes_with_unread_message_counts = boxes_with_unread_message_counts
    @all_unread_messages_count = boxes_with_unread_message_counts.values.sum
  end
end
