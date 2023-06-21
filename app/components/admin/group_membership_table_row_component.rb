# frozen_string_literal: true

class Admin::GroupMembershipTableRowComponent < ViewComponent::Base
  with_collection_parameter :group_membership

  def initialize(group_membership:)
    @group_membership = group_membership
  end

end