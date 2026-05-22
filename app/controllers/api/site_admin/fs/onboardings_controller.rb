class Api::SiteAdmin::Fs::OnboardingsController < Api::SiteAdminController
  rescue_from ActiveRecord::RecordNotUnique do
    render_conflict("Tenant with the same name, ico or saml identifier already exists")
  end

  rescue_from ActiveRecord::RecordInvalid do
    render_conflict("Tenant with the same name, ico or saml identifier already exists")
  end

  def create
    onboard = ::Fs::OnboardingService.new(onboarding_params)

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
      :ico,
      :admin_user_name,
      :saml_identifier,
      :admin_user_contact_email,
      :trial
    )
  end
end
