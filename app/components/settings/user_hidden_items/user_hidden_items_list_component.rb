class Settings::UserHiddenItems::UserHiddenItemsListComponent < ViewComponent::Base
  def initialize(type, items)
    @type = type
    @items = items
  end
end
