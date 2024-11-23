class Filters::FiltersListComponent < ViewComponent::Base
  renders_one :blank_results_area
  def initialize(filters)
    @filters = filters
  end
end
