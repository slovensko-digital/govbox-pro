class TW::SidebarMenuItemComponent < ViewComponent::Base
  renders_one :leading
  renders_one :trailing

  def initialize(name:, url:, icon:, variant: :regular, classes: '')
    @name = name
    @url = url
    @icon_component = icon
    @variant = variant
    @classes = classes
  end

  def regular?
    @variant == :regular
  end

  def light?
    @variant == :light
  end
end
