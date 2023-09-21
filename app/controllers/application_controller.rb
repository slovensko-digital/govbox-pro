class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index
  before_action :set_menu_context, :set_inbox_tag

  def pundit_user
    Current.user
  end

  def get_menu
    @menu
  end

  def set_menu_context
    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::Scope).where(visible: true).where.not(name: Tag::INBOX_TAG_NAME)
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags })
  end

  def set_inbox_tag
    @inbox_tag = Tag.inbox_tag(Current.tenant) if pundit_user
  end
end
