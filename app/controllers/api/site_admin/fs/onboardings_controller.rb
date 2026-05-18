class Api::SiteAdmin::Fs::OnboardingsController < Api::SiteAdminController
  def create
    onboard = ::Fs::OnboardTenant.new(onboarding_params)

    if onboard.valid?
      @tenant = onboard.call
    else
      render status: :bad_request, json: { message: onboard.errors.first.full_message }
    end
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
