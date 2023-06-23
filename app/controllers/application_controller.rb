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
    @menu = SidebarMenu.new(controller_name)
  end
end
