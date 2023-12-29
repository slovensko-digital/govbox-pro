class Api::MessageThreadsController < Api::TenantController
  def show
    @thread = @tenant.message_threads.find(params[:id])
  end
end
