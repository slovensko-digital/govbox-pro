# frozen_string_literal: true

class Admin::TagUserTableRowComponent < ViewComponent::Base
  with_collection_parameter :tag_user

  def initialize(tag_user:)
    @tag_user = tag_user
  end

end