class TW::SidebarMenuItemComponent < ViewComponent::Base
  renders_one :accessory

  def initialize(name:, url:, icon:, variant: :regular)
    @name = name
    @url = url
    @icon_component = icon
    @variant = variant
  end

  def regular?
    @variant == :regular
  end

  def light?
    @variant == :light
  end
end
