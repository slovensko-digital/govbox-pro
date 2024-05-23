class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, _action, parameters = nil, filters: [], tags: [])
    @parameters = parameters
    @filters = filters
    @tags = tags
    @menu = current_menu(controller)
  end

  attr_reader :menu

  private

  def current_menu(controller)
    return admin_menu + site_admin_menu if Current.user.admin? && controller.in?(%w[groups users tags tag_groups automation_rules boxes filters user_hidden_items])
    return settings_menu if controller.in? %w[filters tags user_hidden_items]

    default_main_menu
  end

  def default_main_menu
    [
      TW::SidebarMenuItemComponent.new(name: 'Všetky správy', url: message_threads_path, icon: Common::IconComponent.new("envelope")),
      Layout::FilterListComponent.new(filters: @filters),
      Layout::TagListComponent.new(tags: @tags),
      TW::SidebarMenuItemComponent.new(name: 'Nastavenia', url: filters_path, icon: Icons::CogSixToothComponent.new)
    ]
  end

  def settings_menu
    [
      Layout::BackToBoxComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Filtre', url: filters_path, icon: Icons::BookmarkComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::FunnelComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Viditeľnosť štítkov', url: settings_user_hidden_items_path(type: "Tag"), icon: Common::IconComponent.new("tag")),
      TW::SidebarMenuItemComponent.new(name: 'Viditeľnosť filtrov', url: settings_user_hidden_items_path(type: "Filter"), icon: Common::IconComponent.new("bookmark"))
    ]
  end

  def admin_menu
    return [] unless Current.user.admin?

    [
      Layout::BackToBoxComponent.new,
      TW::SidebarMenuDividerComponent.new(name: 'Nastavenia'),
      TW::SidebarMenuItemComponent.new(name: 'Filtre', url: filters_path, icon: Icons::BookmarkComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Pravidlá', url: settings_automation_rules_path, icon: Icons::FunnelComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Viditeľnosť štítkov', url: settings_user_hidden_items_path(type: Tag), icon: Common::IconComponent.new("bookmark")),
      TW::SidebarMenuItemComponent.new(name: 'Viditeľnosť filtrov', url: settings_user_hidden_items_path(type: "Filter"), icon: Common::IconComponent.new("tag")),
      TW::SidebarMenuDividerComponent.new(name: 'Administrácia'),
      TW::SidebarMenuItemComponent.new(name: 'Používatelia', url: admin_tenant_users_path(Current.tenant), icon: Icons::UsersComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Prístup', url: admin_tenant_tag_groups_path(Current.tenant), icon: Icons::LockClosedComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Schránky', url: admin_tenant_boxes_path(Current.tenant), icon: Icons::RectangleStackComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Skupiny', url: admin_tenant_groups_path(Current.tenant), icon: Icons::UserGroupsComponent.new),
      TW::SidebarMenuItemComponent.new(name: 'Štítky', url: admin_tenant_tags_path(Current.tenant), icon: Icons::TagComponent.new)
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
