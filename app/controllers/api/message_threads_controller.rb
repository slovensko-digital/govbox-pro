class Api::MessageThreadsController < Api::TenantController
  def index
    @threads = @tenant.message_threads.where('message_threads.id > ?', params[:offset]).order(:id).limit(API_PAGE_SIZE) if params[:offset]
    @threads = @tenant.message_threads.order(:id).limit(API_PAGE_SIZE) unless params[:offset]
  end

  def show
    @thread = @tenant.message_threads.find(params[:id])
  end
end
