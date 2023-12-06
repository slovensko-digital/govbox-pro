class NewMessageComponent < ViewComponent::Base
  def initialize(templates_list:, boxes:)
    @templates_list = templates_list
    @boxes = boxes
  end
end
