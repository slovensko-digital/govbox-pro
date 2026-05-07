class Api::UsersController < Api::TenantController
  def index
    @users = @tenant.users.order(:id)
  end
end
