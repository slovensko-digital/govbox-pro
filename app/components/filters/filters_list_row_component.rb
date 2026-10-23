class Filters::FiltersListRowComponent < ViewComponent::Base
  def initialize(filter, preference: nil, subscriptions: [], overridden: false)
    @filter = filter
    @preference = preference
    @subscriptions = subscriptions
    @overridden = overridden
  end
end
