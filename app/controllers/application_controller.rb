class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index
  before_action :set_menu_context

  def pundit_user
    Current.user
  end

  def set_menu_context
    return unless Current.user

    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::ScopeListable).where(visible: true)
    @filters = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable).order(:position)
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags, filters: @filters }).menu
    @current_tenant_boxes_count = Current.tenant.boxes.count
  end
end
