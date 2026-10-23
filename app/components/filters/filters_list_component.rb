class Filters::FiltersListComponent < ViewComponent::Base
  renders_one :blank_results_area
  def initialize(filters, subscriptions: {})
    @filters = filters
    @subscriptions = subscriptions
    @personal_queries = filters.reject(&:common?).map(&:query).to_set
  end
end
