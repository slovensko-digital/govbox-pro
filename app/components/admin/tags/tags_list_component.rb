class Admin::Tags::TagsListComponent < ViewComponent::Base
  renders_one :blank_results_area
  def initialize(simple_tags:)
    @simple_tags = simple_tags
  end
end
