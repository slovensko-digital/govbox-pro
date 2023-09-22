class Admin::Permissions::GroupsListRowComponent < ViewComponent::Base
  with_collection_parameter :group
  def initialize(group:)
    @group = group
  end
end
