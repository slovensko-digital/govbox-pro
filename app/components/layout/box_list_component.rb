class Layout::BoxListComponent < ViewComponent::Base
  with_collection_parameter :box
  def initialize(box:)
    @box = box
    @unread_messages = Pundit.policy_scope(Current.user, Message).joins(thread: { folder: :box }).where(box: { id: @box.id}, read: false).size
  end
end
