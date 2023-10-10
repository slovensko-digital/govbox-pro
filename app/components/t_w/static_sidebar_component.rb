class TW::StaticSidebarComponent < ViewComponent::Base
  def initialize(menu:)
    @menu = menu
  end
end
