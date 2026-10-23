class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, action, parameters = nil)
    @parameters = parameters
    @controller = controller
    @action = action
  end

  # Mobile and desktop sidebars must not share single-use component instances.
  def menu
    initial_structure(@controller, @action)
  end

  private

  def initial_structure(controller, _action)
    return settings_menu if @parameters[:personalized] && controller.in?(%w[filters user_filter_visibilities]) && !Current.user.admin?
    return admin_menu + site_admin_menu if controller.in? %w[groups users tags permissions automation_rules boxes api_connections api_accesses filters automation_webhooks feature_flags user_filter_visibilities]

    default_main_menu
  end

  def default_main_menu
    if @parameters[:personalized]
      return [
        Layout::FilterListComponent.new(filters: @parameters[:filters], query: @parameters[:query]),
        Layout::SystemFilterListComponent.new(tags: @parameters[:system_tags] || [], filters: @parameters[:filters], query: @parameters[:query]),
        TW::SidebarMenuItemComponent.new(name: 'Nastavenia', url: filters_path, icon: Icons::CogSixToothComponent.new)
      ]
    end

    [
      TW::SidebarMenuItemComponent.new(name: 'Všetky správy', url: message_threads_path(q: ""), icon: Common::IconComponent.new("envelope")),
      Layout::FilterListComponent.new(filters: @parameters[:filters]),
      Layout::TagListComponent.new(tags: @parameters[:tags]),
      TW::SidebarMenuItemComponent.new(name: 'Nastavenia', url: filters_path, icon: Icons::CogSixToothComponent.new)
    ]
  end

  def settings_menu
    [
      Layout::BackToBoxComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Filtre', url: filters_path, icon: Icons::BookmarkComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Moje menu', url: settings_user_filter_visibilities_path, icon: Icons::RectangleGroupComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::FunnelComponent.new)
    ]
  end

  def admin_menu
    return [] unless Current.user.admin?

    [
      Layout::BackToBoxComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Filtre', url: filters_path, icon: Icons::BookmarkComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Moje menu', url: settings_user_filter_visibilities_path, icon: Icons::RectangleGroupComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::FunnelComponent.new),
      TW::SidebarMenuDividerComponent.new(name: 'Administrácia'),
      TW::SidebarMenuItemComponent.new(name: 'Používatelia', url: admin_tenant_users_path(Current.tenant), icon: Icons::UsersComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Prístup', url: admin_tenant_permissions_path(Current.tenant), icon: Icons::LockClosedComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Schránky', url: admin_tenant_boxes_path(Current.tenant), icon: Common::IconComponent.new("inbox-stack")),
      TW::SidebarMenuItemComponent.new(name: 'API Prepojenia', url: admin_tenant_api_connections_path(Current.tenant), icon: Icons::RectangleStackComponent.new),
      *(TW::SidebarMenuItemComponent.new(name: 'API Prístup', url: admin_tenant_api_access_path(Current.tenant), icon: Common::IconComponent.new("key")) if Current.tenant.feature_enabled?(:api)),
      TW::SidebarMenuItemComponent.new(name: 'Skupiny', url: admin_tenant_groups_path(Current.tenant), icon: Icons::UserGroupsComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Štítky', url: admin_tenant_tags_path(Current.tenant), icon: Icons::TagComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Integrácie', url: admin_tenant_automation_webhooks_path(Current.tenant), icon: Common::IconComponent.new("code-bracket")),
      *(TW::SidebarMenuItemComponent.new(name: 'Funkcie', url: admin_tenant_feature_flags_path(Current.tenant), icon: Common::IconComponent.new("puzzle-piece"))  if Current.tenant.list_available_features.present?)
    ]
  end

  def site_admin_menu
    return [] unless Current.user.site_admin?

    [
      Layout::SidebarDividerComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Admin'),
      TW::SidebarMenuItemComponent.new(name: 'Good Job Dashboard', url: good_job_path, icon: Icons::CogSixToothComponent.new)
    ]
  end
end
