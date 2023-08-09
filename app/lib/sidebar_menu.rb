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
    return default_message_thread_menu if %w[messages message_drafts].include?(controller)
    return admin_main_menu if Current.user.admin? || Current.user.site_admin?

    default_main_menu
  end

  def default_main_menu
    [
      TW::SidebarMenuItemComponent.new(name: 'Prehľad', url: root_path, icon: Icons::DashboardComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Správy', url: message_threads_path, icon: Icons::SchrankaComponent.new),
      Layout::TagListComponent.new(tags: @parameters[:tags])
    ]
  end

  def admin_main_menu
    [
      TW::SidebarMenuItemComponent.new(name: 'Prehľad', url: root_path, icon: Icons::DashboardComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Správy', url: message_threads_path, icon: Icons::SchrankaComponent.new),
      Layout::TagListComponent.new(tags: @parameters[:tags]),
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Nastavenie pravidiel', url: settings_automation_rules_path, icon: Icons::SettingsComponent.new),
      TW::SidebarMenuDividerComponent.new(name: 'Administrácia'),
      TW::SidebarMenuItemComponent.new(name: 'Schránky', url: boxes_path, icon: Icons::BoxesComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Administrácia', url: admin_tenants_path, icon: Icons::AdminComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Good Job Dashboard', url: good_job_path, icon: Icons::GoodJobComponent.new)
    ]
  end

  def default_message_thread_menu
    [Layout::BackToBoxComponent.new, Layout::MessageThreadSidebarComponent.new(message: @parameters[:message])] if @parameters && @parameters[:message]
  end
end
