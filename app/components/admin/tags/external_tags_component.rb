class Admin::Tags::ExternalTagsComponent < ViewComponent::Base
  def initialize(tags)
    @tags = tags
  end
end
