class Api::SiteAdmin::Fs::OnboardingsController < Api::SiteAdminController
  def create
    ::Fs::OnboardTenant.new(
      tenant_name: onboarding_params[:tenant_name],
      admin_user_name: onboarding_params[:admin_user_name],
      saml_identifier: onboarding_params[:saml_identifier],
      admin_user_contact_email: onboarding_params[:admin_user_contact_email],
      fs_api_sub: onboarding_params[:fs_api_sub],
      fs_api_private_key: onboarding_params[:fs_api_private_key]
    ).call

    head :created
  end

  private

  def onboarding_params
    params.require(:onboarding).permit(
      :tenant_name,
      :admin_user_name,
      :saml_identifier,
      :admin_user_contact_email,
      :fs_api_sub,
      :fs_api_private_key
    )
  end
end
