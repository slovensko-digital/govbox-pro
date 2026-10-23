class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, action, parameters = nil)
    @parameters = parameters
    @controller = controller
    @action = action
  end

  # Each entry describes a partial and its local data, shared by both sidebars.
  def menu
    initial_structure(@controller, @action)
  end

  private

  def initial_structure(controller, _action)
    return admin_menu + site_admin_menu if controller.in? %w[groups users tags permissions automation_rules boxes api_connections api_accesses filters automation_webhooks feature_flags]

    default_main_menu
  end

  def default_main_menu
    [
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Všetky správy', url: message_threads_path, icon: { partial: "common/icon", locals: { icon: "envelope" } } } },
      { partial: "layout/filter_list", locals: { filters: @parameters[:filters] } },
      { partial: "layout/tag_list", locals: { tags: @parameters[:tags] } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Nastavenia', url: filters_path, icon: { partial: "icons/cog_six_tooth" } } }
    ]
  end

  def admin_menu
    return [] unless Current.user.admin?

    [
      { partial: "layout/back_to_box", locals: {} },
      { partial: "t_w/sidebar_menu_divider", locals: { name: 'Nastavenia' } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Filtre', url: filters_path, icon: { partial: "icons/bookmark" } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Pravidlá', url: settings_automation_rules_path, icon: { partial: "icons/funnel" } } },
      { partial: "t_w/sidebar_menu_divider", locals: { name: 'Administrácia' } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Používatelia', url: admin_tenant_users_path(Current.tenant), icon: { partial: "icons/users" } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Prístup', url: admin_tenant_permissions_path(Current.tenant), icon: { partial: "icons/lock_closed" } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Schránky', url: admin_tenant_boxes_path(Current.tenant), icon: { partial: "common/icon", locals: { icon: "inbox-stack" } } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'API Prepojenia', url: admin_tenant_api_connections_path(Current.tenant), icon: { partial: "icons/rectangle_stack" } } },
      *([{ partial: "t_w/sidebar_menu_item", locals: { name: 'API Prístup', url: admin_tenant_api_access_path(Current.tenant), icon: { partial: "common/icon", locals: { icon: "key" } } } }] if Current.tenant.feature_enabled?(:api)),
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Skupiny', url: admin_tenant_groups_path(Current.tenant), icon: { partial: "icons/user_groups" } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Štítky', url: admin_tenant_tags_path(Current.tenant), icon: { partial: "icons/tag" } } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Integrácie', url: admin_tenant_automation_webhooks_path(Current.tenant), icon: { partial: "common/icon", locals: { icon: "code-bracket" } } } },
      *([{ partial: "t_w/sidebar_menu_item", locals: { name: 'Funkcie', url: admin_tenant_feature_flags_path(Current.tenant), icon: { partial: "common/icon", locals: { icon: "puzzle-piece" } } } }]  if Current.tenant.list_available_features.present?)
    ]
  end

  def site_admin_menu
    return [] unless Current.user.site_admin?

    [
      { partial: "layout/sidebar_divider", locals: {} },
      { partial: "t_w/sidebar_menu_divider", locals: { name: 'Admin' } },
      { partial: "t_w/sidebar_menu_item", locals: { name: 'Good Job Dashboard', url: good_job_path, icon: { partial: "icons/cog_six_tooth" } } }
    ]
  end
end
