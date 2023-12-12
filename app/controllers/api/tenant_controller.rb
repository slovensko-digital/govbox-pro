class Api::TenantController < ApiController
  private

  def authenticate_user
    @tenant = ApiEnvironment.tenant_token_authenticator.verify_token(authenticity_token)
  end
end
