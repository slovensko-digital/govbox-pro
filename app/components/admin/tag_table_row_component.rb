# frozen_string_literal: true

class Admin::TagTableRowComponent < ViewComponent::Base
  with_collection_parameter :tag

  def initialize(tag:, group: "", tag_action: "")
    @tag = tag
    @group = group
    @tag_action = tag_action
  end
end
