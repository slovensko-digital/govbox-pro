class Filters::FiltersListRowComponent < ViewComponent::Base
  def initialize(filter, subscriptions: [], overridden: false)
    @filter = filter
    @subscriptions = subscriptions
    @overridden = overridden
  end
end
