class TW::SidebarMenuItemComponent < ViewComponent::Base
  def initialize(name:, url:, icon:)
    @name = name
    @url = url
    @icon_component = icon
  end
end
