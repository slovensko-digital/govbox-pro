class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index
  before_action :set_menu_context

  def pundit_user
    Current.user
  end

  def get_menu
    @menu
  end

  def set_menu_context
    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::Scope).where(visible: true)
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags })
  end

  def render_forbidden(key, value: nil)
    render status: :forbidden, json: { message: I18n.t("forbidden.#{key}", value: value, locale: :en) }
  end
end
