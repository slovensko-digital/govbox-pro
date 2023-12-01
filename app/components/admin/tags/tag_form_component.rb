class Admin::Tags::TagFormComponent < ViewComponent::Base
  def initialize(tag:)
    @tag = tag
  end
end
