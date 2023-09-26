class Filters::FilterFormComponent < ViewComponent::Base
  def initialize(filter:, action:)
    @filter = filter
    @action = action
  end
end
