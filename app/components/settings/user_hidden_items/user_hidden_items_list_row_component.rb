class Settings::UserHiddenItems::UserHiddenItemsListRowComponent < ViewComponent::Base
  with_collection_parameter :item
  def initialize(item:, type: "Tag")
    @type = type
    @item = item
  end
end
