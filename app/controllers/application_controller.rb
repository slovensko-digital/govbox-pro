class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index if respond_to?(:index)
  before_action :set_menu_context

  def pundit_user
    Current.user
  end

  def set_menu_context
    return unless Current.user

    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::ScopeListable)
            .where(visible: true)
            .where.not(id: UserHiddenItem.where(user: Current.user, user_hideable_type: "Tag").select(:user_hideable_id))
            .order(:name)
    @filters = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable)
               .where.not(id: UserHiddenItem.where(user: Current.user, user_hideable_type: "Filter").select(:user_hideable_id))
               .order(:position)
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags, filters: @filters }).menu
    @current_tenant_boxes_count = Current.tenant.boxes.count
  end
end
