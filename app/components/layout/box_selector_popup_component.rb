class Layout::BoxSelectorPopupComponent < ViewComponent::Base
    def initialize
      @boxes = Current.tenant.boxes.where.not(boxes: { id: nil }) || []
      @all_unread_messages = Pundit.policy_scope(Current.user, Message).where(read:false) if Current.user
    end
end