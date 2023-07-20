class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(controller, action)
    @menu = initial_structure(controller, action)
  end

  def get_menu
    @menu
  end

  private

  def initial_structure(controller, action)
    return default_message_thread_menu if ['messages', 'draft_messages'].include?(controller)
    return admin_main_menu if Current.user.admin? || Current.user.site_admin?

    default_main_menu
  end

  def default_main_menu
    [
      { icon: Icons::DashboardComponent.new, url: root_path, name: 'Dashboard' },
      { icon: Icons::SchrankaComponent.new, url: message_threads_path, name: 'Správy' },
      { icon: Icons::SettingsComponent.new, url: settings_automation_rules_path, name: 'Rules Settings' },
      :tagsplaceholder
    ]
  end

  def admin_main_menu
    [
      { icon: Icons::DashboardComponent.new, url: root_path, name: 'Dashboard' },
      { icon: Icons::BoxesComponent.new, url: boxes_path, name: 'Schránky' },
      { icon: Icons::SchrankaComponent.new, url: message_threads_path, name: 'Správy' },
      { icon: Icons::AdminComponent.new, url: admin_tenants_path, name: 'Administracia' },
      { icon: Icons::GoodJobComponent.new, url: good_job_path, name: 'Good Job Dashboard' },
      { icon: Icons::SettingsComponent.new, url: settings_automation_rules_path, name: 'Rules Settings' },
      :tagsplaceholder
    ]
  end

  def default_message_thread_menu
    %i[back_to_box_placeholder message_thread_placeholder]
  end

  def default_settings_menu
    [
      { icon: 'Profile', url: settings_profile_path, name: 'User profile' },
      { icon: 'Tags', url: settings_tags_path, name: 'Tags' },
      { icon: 'Rules', url: settings_automation_rules_path, name: 'Rules' }
    ]
  end
end
