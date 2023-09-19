class Admin::Tags::TagFormComponent < ViewComponent::Base
  def initialize(tag:, action:)
    @tag = tag
    @actio = action
  end
end
