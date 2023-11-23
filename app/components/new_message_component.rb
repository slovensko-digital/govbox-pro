class NewMessageComponent < ViewComponent::Base
  def initialize(templates_list:)
    @templates_list = templates_list
  end
end
