class Admin::Tags::TagsListRowComponent < ViewComponent::Base
  with_collection_parameter :tag
  def initialize(tag:)
    @tag = tag
  end
end
