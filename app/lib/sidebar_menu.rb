class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, action, parameters = nil)
    @parameters = parameters
    @menu = initial_structure(controller, action)
  end

  attr_reader :menu

  private

  def initial_structure(controller, _action)
    return admin_main_menu if (controller.in? %w[groups users tags tag_groups automation_rules boxes tenants
                                                 filters]) && (Current.user.admin? || Current.user.site_admin?)

    default_main_menu
  end

  def default_main_menu
    [
      TW::SidebarMenuItemComponent.new(name: 'Všetky správy', url: message_threads_path, icon: Icons::EnvelopeComponent.new),
      Layout::FilterListComponent.new(filters: @parameters[:filters]),
      Layout::TagListComponent.new(tags: @parameters[:tags]),
      TW::SidebarMenuItemComponent.new(name: 'Nastavenia', url: filters_path, icon: Icons::CogSixToothComponent.new)
    ]
  end

  def admin_main_menu
    [
      Layout::BackToBoxComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Filtre', url: filters_path, icon: Icons::BookmarkComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::FunnelComponent.new),
      TW::SidebarMenuDividerComponent.new(name: 'Administrácia'),
      Current.user.site_admin? ? TW::SidebarMenuItemComponent.new(name: 'Tenanti', url: admin_tenants_path, icon: Icons::RectangleGroupComponent.new) : nil,
      TW::SidebarMenuItemComponent.new(name: 'Používatelia', url: admin_tenant_users_path(Current.tenant), icon: Icons::UsersComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Prístup', url: admin_tenant_tag_groups_path(Current.tenant), icon: Icons::LockClosedComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Schránky', url: admin_tenant_boxes_path(Current.tenant), icon: Icons::RectangleStackComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Skupiny', url: admin_tenant_groups_path(Current.tenant), icon: Icons::UserGroupsComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Štítky', url: admin_tenant_tags_path(Current.tenant), icon: Icons::TagComponent.new),
      Layout::SidebarDividerComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Admin'),
      TW::SidebarMenuItemComponent.new(name: 'Good Job Dashboard', url: good_job_path, icon: Icons::CogSixToothComponent.new),
    ].compact
  end
end
