class Admin::Tags::TagsListComponent < ViewComponent::Base
  def initialize(external_tags:, simple_tags:)
    @external_tags = external_tags
    @simple_tags = simple_tags
  end
end
