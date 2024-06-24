class Settings::UserFilterVisibilities::ListRowComponent < ViewComponent::Base
  with_collection_parameter :visibility
  def initialize(visibility:)
    @visibility = visibility
    @filter = visibility.filter
  end
end
