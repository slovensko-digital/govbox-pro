class Admin::Permissions::TagComponent < ViewComponent::Base
  def initialize(tag:)
    @tag = tag
  end
end
