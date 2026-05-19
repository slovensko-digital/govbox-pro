class Api::TenantController < ApiController
  private

  def authenticate_user
    @tenant = ApiEnvironment.tenant_token_authenticator.verify_token(authenticity_token)
  rescue JWT::VerificationError, JWT::InvalidSubError, JWT::InvalidPayload => error
    render_unauthorized(error.message)
  end
end
