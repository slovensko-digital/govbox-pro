class Admin::Tags::TagsListComponent < ViewComponent::Base
  def initialize(simple_tags:)
    @simple_tags = simple_tags
  end
end
