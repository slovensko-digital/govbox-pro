class Api::BoxesController < Api::TenantController
  def index
    @boxes = @tenant.boxes.order(:id)
  end
end
