class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, action, parameters = nil)
    @parameters = parameters
    @menu = initial_structure(controller, action)
  end

  def get_menu
    @menu
  end

  private

  def initial_structure(controller, action)
    return default_message_thread_menu if controller.in? %w[messages message_drafts]
    return admin_main_menu if (controller.in? %w[groups users tags automation_rules boxes]) && (Current.user.admin? || Current.user.site_admin?)

    default_main_menu
  end

  def default_main_menu
    [
      TW::SidebarMenuItemComponent.new(name: 'Prehľad', url: root_path, icon: Icons::DashboardComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Správy', url: message_threads_path, icon: Icons::SchrankaComponent.new),
      Layout::TagListComponent.new(tags: @parameters[:tags]),
      TW::SidebarMenuItemComponent.new(name: 'Nastavenia', url: admin_tenant_users_path(Current.tenant), icon: Icons::SettingsComponent.new)
    ]
  end

  def admin_main_menu
    [
      Layout::BackToBoxComponent.new(),
      TW::SidebarMenuDividerComponent.new(name: 'Produkt'),
      TW::SidebarMenuItemComponent.new(name: 'Používatelia', url: admin_tenant_users_path(Current.tenant), icon: Icons::UsersComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::RulesComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Schránky', url: boxes_path, icon: Icons::BoxesComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Skupiny', url: admin_tenant_groups_path(Current.tenant), icon: Icons::GroupsComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Štítky', url: admin_tenant_tags_path(Current.tenant), icon: Icons::TagsComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Good Job Dashboard', url: good_job_path, icon: Icons::GoodJobComponent.new),
    ]
  end

  def default_message_thread_menu
    [Layout::BackToBoxComponent.new, Layout::MessageThreadSidebarComponent.new(message: @parameters[:message])] if @parameters && @parameters[:message]
  end
end
