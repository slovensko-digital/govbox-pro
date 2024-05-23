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

    @tags = Current.user.build_tag_visibilities!.where(visible: true).map(&:user_item)
    @filters = Current.user.build_filter_visibilities!.where(visible: true).map(&:user_item)
    @menu = SidebarMenu.new(controller_name, action_name, tags: @tags, filters: @filters).menu
    @current_tenant_boxes_count = Current.tenant.boxes.count
  end
end
