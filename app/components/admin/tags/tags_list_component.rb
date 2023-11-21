class Admin::Tags::TagsListComponent < ViewComponent::Base
  def initialize(external_tags:, internal_tags:)
    @external_tags = external_tags
    @internal_tags = internal_tags
  end
end
