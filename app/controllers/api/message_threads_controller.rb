class Api::MessageThreadsController < Api::TenantController
  def show
    @thread = MessageThread.joins(:box).where(box: { tenant_id: @tenant.id }).find(params[:id])
  end
end
