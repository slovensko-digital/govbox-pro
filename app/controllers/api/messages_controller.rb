class Api::MessagesController < Api::TenantController
  def show
    @message = Message.joins(thread: :box).where(box: { tenant_id: @tenant.id }).find(params[:id])
  end
end
