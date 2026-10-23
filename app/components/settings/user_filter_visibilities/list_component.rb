class Settings::UserFilterVisibilities::ListComponent < ViewComponent::Base
  def initialize(shown_filters:, hidden_filters:, preferences:)
    @shown_filters = shown_filters
    @hidden_filters = hidden_filters
    @preferences = preferences
  end
end
