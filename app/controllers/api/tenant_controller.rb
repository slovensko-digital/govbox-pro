class Api::TenantController < ApiController
  private

  def authenticate_user
    ApiEnvironment.tenant_token_authenticator.verify_token(authenticity_token)
  end
end
