# frozen_string_literal: true

class Admin::GroupTableRowComponent < ViewComponent::Base
  with_collection_parameter :group

  def initialize(group:, user: '', group_action: '')
    @group = group
    @user = user
    @group_action = group_action
  end
end
