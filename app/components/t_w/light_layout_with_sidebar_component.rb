class TW::LightLayoutWithSidebarComponent < ViewComponent::Base
  renders_one :mobile_sidebar
  renders_one :static_sidebar
  renders_one :top_navigation
  renders_one :main_content
end
