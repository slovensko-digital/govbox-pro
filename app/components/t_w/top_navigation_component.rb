class TW::TopNavigationComponent < ViewComponent::Base
  def initialize(current_tenant_boxes_count)
    @current_tenant_boxes_count = current_tenant_boxes_count
  end
end
