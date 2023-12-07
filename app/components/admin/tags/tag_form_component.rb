class Admin::Tags::TagFormComponent < ViewComponent::Base
  include ColorizedHelper, IconizedHelper
  def initialize(tag:)
    @tag = tag
  end
end
