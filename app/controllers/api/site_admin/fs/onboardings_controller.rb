class Api::SiteAdmin::Fs::OnboardingsController < Api::SiteAdminController
  rescue_from ActiveRecord::RecordInvalid do |e|
    if e.record.errors.details[:saml_identifier]&.any? { |error| error[:error] == :taken }
      render_conflict("Saml identifier has already been taken")
    else
      render status: :unprocessable_content, json: { message: "Invalid onboarding data" }
    end
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
