class TW::SidebarMenuItemComponent < ViewComponent::Base
  def initialize(name:, url:, icon:)
    @name = name
    @url = url
    if icon
      @icon_component =
        "Icons::#{icon}Component"
          .split('::')
          .inject(Object) { |o, c| o.const_get c }
    end
  end
end
