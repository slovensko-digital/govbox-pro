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
    return default_message_thread_menu if controller == 'messages'
    return admin_main_menu if Current.user.admin? || Current.user.site_admin?

    default_main_menu
  end

  def default_main_menu
    [
      { icon: 'Dashboard', url: root_path, name: 'Dashboard' },
      { icon: 'Schranka', url: message_threads_path, name: 'Správy' },
      { icon: 'Settings', url: settings_automation_rules_path, name: 'Rules Settings' },
      :tagsplaceholder
    ]
  end

  def admin_main_menu
    [
      { icon: 'Dashboard', url: root_path, name: 'Dashboard' },
      { icon: 'Boxes', url: boxes_path, name: 'Schranky' },
      { icon: 'Schranka', url: message_threads_path, name: 'Správy' },
      { icon: 'Admin', url: admin_tenants_path, name: 'Administracia' },
      { icon: 'GoodJob', url: good_job_path, name: 'Good Job Dashboard' },
      { icon: 'Settings', url: settings_automation_rules_path, name: 'Rules Settings' },
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
