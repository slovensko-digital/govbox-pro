class Api::MessagesController < Api::TenantController
  def show
    @message = @tenant.messages.find(params[:id])
  end
end
