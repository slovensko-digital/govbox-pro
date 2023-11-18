class Layout::BoxListComponent < ViewComponent::Base
  with_collection_parameter :box

  def initialize(box:)
    @box = box
    # TODO pass data as param
    @unread_messages = Pundit.policy_scope(Current.user, Message).joins(thread: :box).where(box: { id: @box.id}, read: false).count
  end
end
