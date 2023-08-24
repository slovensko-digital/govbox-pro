# frozen_string_literal: true

class Admin::TagGroupTableRowComponent < ViewComponent::Base
  with_collection_parameter :tag_group

  def initialize(tag_group:)
    @tag_group = tag_group
  end

end
