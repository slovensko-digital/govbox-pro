class Layout::BoxSelectorComponent < ViewComponent::Base
  def initialize(current_tenant_boxes_count)
    @disabled = current_tenant_boxes_count == 1
  end
end
