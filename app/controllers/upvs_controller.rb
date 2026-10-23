class UpvsController < ActionController::API
  include Authentication
  skip_before_action :authenticate

  def login
    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    saml_identifier = response.attributes["Subject.UPVSIdentityID"]
    username = response.attributes["Actor.FormattedName"]

    Current.user = User.find_by(saml_identifier: saml_identifier)

    if Current.user.nil? && session[:ssd_trial_return_url].present?
      return_url = session.delete(:ssd_trial_return_url)
      token = JWT.encode(
        {
          saml_identifier: saml_identifier,
          username: username,
          exp: 5.minutes.from_now.to_i
        },
        ENV.fetch("SSD_TRIAL_SHARED_SECRET"),
        "HS256"
      )

      uri = URI.parse(return_url)

      uri.query = URI.encode_www_form(
        URI.decode_www_form(uri.query.to_s).append(["token", token])
      )

      return redirect_to(uri.to_s, allow_other_host: true)
    end

    session.delete(:ssd_trial_return_url)

    create_session(saml_identifier: saml_identifier, username: username)
    EventBus.publish(:user_logged_in, Current.user) if Current.user
  end

  def logout
    if params[:SAMLRequest]
      EventBus.publish(:user_logged_out, User.find_by(id: session[:user_id]))
      clean_session

      redirect_to "/auth/saml/slo?#{slo_request_params.to_query}"
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{slo_response_params.to_query}"
    else
      clean_session
      redirect_to '/auth/saml/spslo'
    end
  end

  private

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params(redirect_url: root_path)
    params.permit(:SAMLResponse, :SigAlg, :Signature).merge(RelayState: redirect_url)
  end
end
