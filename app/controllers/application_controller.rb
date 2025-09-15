class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Localization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index if respond_to?(:index)
  before_action :set_menu_context
  before_action :http_authenticate

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

  def http_authenticate
    return unless ENV['REQUIRE_HTTP_AUTH'] == 'true'

    authenticate_or_request_with_http_basic do |username, password|
      user = User.find_by(username: username)
      user&.authenticate(password)
    end
  end
end
