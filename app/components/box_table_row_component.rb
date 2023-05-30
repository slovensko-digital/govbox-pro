# frozen_string_literal: true

class BoxTableRowComponent < ViewComponent::Base
  with_collection_parameter :box

  def initialize(box:, user: "", box_action: "")
    @box = box
    @user = user
    @box_action = box_action
  end
end
