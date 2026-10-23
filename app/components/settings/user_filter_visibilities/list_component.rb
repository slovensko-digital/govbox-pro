class Settings::UserFilterVisibilities::ListComponent < ViewComponent::Base
  def initialize(filters:, preferences:)
    @filters = filters
    @preferences = preferences
  end
end
