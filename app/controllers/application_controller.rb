class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index if respond_to?(:index)
  before_action :set_menu_context

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    Current.user
  end

  def set_menu_context
    return unless Current.user

    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::ScopeListable).where(visible: true).order(:name)
    @filters = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable).order(:position)
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags, filters: @filters }).menu
  end

  private

  def user_not_authorized(exception)
    flash[:alert] = "Prístup bol zamietnutý"
    redirect_to(request.referer || root_path)
  end
end
