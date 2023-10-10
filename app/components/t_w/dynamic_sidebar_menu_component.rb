class TW::DynamicSidebarMenuComponent < ViewComponent::Base
  def before_render
    @menu = controller.menu
  end
end
