class Admin::Tags::TagsListComponent < ViewComponent::Base
  def initialize(tags)
    @external_tags = tags.where(external: true).order(:name)
    @internal_tags = tags.where(external: false).order(:name)
  end
end
