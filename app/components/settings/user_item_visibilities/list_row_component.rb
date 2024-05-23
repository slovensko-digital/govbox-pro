class Settings::UserItemVisibilities::ListRowComponent < ViewComponent::Base
  with_collection_parameter :visibility
  def initialize(visibility:)
    @visibility = visibility
    @item = visibility.user_item
  end
end
