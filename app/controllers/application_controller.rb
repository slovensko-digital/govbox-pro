class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Localization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index if respond_to?(:index)
  before_action :set_menu_context

  def pundit_user
    Current.user
  end

  def set_menu_context
    return unless Current.user

    @filters = Current.user.visible_filters
    @menu = SidebarMenu.new(controller_name, action_name, tags: @tags, filters: @filters).menu
    @current_tenant_boxes_count = Current.tenant.boxes.count
  end
end
