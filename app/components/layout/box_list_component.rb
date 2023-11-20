class Layout::BoxListComponent < ViewComponent::Base
  def initialize(box:, unread_message_count:)
    @box = box
    @unread_message_count = unread_message_count
  end
end
