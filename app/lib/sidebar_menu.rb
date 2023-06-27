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
    return initial_message_thread_menu if controller == 'messages'

    initial_main_menu
  end

  def initial_main_menu
    [
      { icon: 'Home', url: root_path, name: 'Dashboard' },
      { icon: 'Boxes', url: boxes_path, name: 'Schranky' },
      { icon: 'Admin', url: admin_tenants_path, name: 'Administracia' },
      { icon: 'GoodJob', url: good_job_path, name: 'Good Job Dashboard' },
      { icon: 'Settings', url: settings_automation_rules_path, name: 'Rules Settings' },
      :tagsplaceholder
    ]
  end

  def initial_message_thread_menu
    %i[back_to_box_placeholder message_thread_placeholder]
  end

  def initial_settings_menu
    [
      { icon: 'Profile', url: settings_profile_path, name: 'User profile' },
      { icon: 'Tags', url: settings_tags_path, name: 'Tags' },
      { icon: 'Rules', url: settings_automation_rules_path, name: 'Rules' }
    ]
  end
end
