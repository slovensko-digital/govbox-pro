class TW::DynamicSidebarMenuComponent < ViewComponent::Base
  def before_render
    @menu = controller.get_menu.get_menu
  end
end
