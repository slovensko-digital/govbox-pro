class SidebarMenu
  include Rails.application.routes.url_helpers

  def initialize(context)
    @menu = initial_structure(context)
  end

  def get_menu
    @menu
  end

  private

  def initial_structure(context)
    #    case context
    #when :main_menu
    initial_main_menu
    #when :settings_menu
    #initial_settings_menu
    #end
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

  def initial_settings_menu
    [
      { icon: 'Profile', url: settings_profile_path, name: 'User profile' },
      { icon: 'Tags', url: settings_tags_path, name: 'Tags' },
      { icon: 'Rules', url: settings_automation_rules_path, name: 'Rules' }
    ]
  end
end
