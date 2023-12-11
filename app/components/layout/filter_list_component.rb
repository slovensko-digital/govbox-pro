class Layout::FilterListComponent < ViewComponent::Base
  include MessageThreadHelper

  def initialize(filters:)
    @filters = filters
  end
end
