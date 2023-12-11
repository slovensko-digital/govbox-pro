class Api::SiteAdminController < ApiController
  private

  def authenticate_user
    ApiEnvironment.site_admin_token_authenticator.verify_token(authenticity_token)
  end
end
