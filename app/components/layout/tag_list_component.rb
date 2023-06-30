class Layout::TagListComponent < ViewComponent::Base
  # TODO: prehodit niekam prec
  include Pundit

  def initialize
    # TODO: prehodit niekam prec
    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::Scope).where(visible: true)
  end
  # TODO: prehodit niekam prec
  def pundit_user
    Current.user
  end
end
