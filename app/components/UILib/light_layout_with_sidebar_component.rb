class UILib::LightLayoutWithSidebarComponent < ViewComponent::Base
  renders_one :static_sidebar
  renders_one :sidebar
  #renders_one :search_box
  renders_one :user_menu
  renders_one :main_content

end