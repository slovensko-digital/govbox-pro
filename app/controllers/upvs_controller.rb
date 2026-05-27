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
    return_url = session.delete(:ssd_trial_return_url).presence || relay_state_trial_return_url

    if Current.user.nil? && return_url.present?
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

    create_session(saml_identifier: saml_identifier)
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

  def relay_state_trial_return_url
    relay_state = params[:RelayState].presence
    return if relay_state.blank?

    return_url = Rails.application.message_verifier(:ssd_trial_return_url).verify(relay_state)
    valid_return_url?(return_url) ? return_url : nil
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def valid_return_url?(url)
    return false if url.blank?

    uri = URI.parse(url.to_s)
    return true if uri.host.nil? && uri.scheme.nil?

    %w[http https].include?(uri.scheme) && allowed_return_urls.include?(url)
  rescue URI::InvalidURIError
    false
  end

  def allowed_return_urls
    ENV.fetch('SSD_TRIAL_RETURN_URL_ALLOWLIST', '').split(',')
  end

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params(redirect_url: root_path)
    params.permit(:SAMLResponse, :SigAlg, :Signature).merge(RelayState: redirect_url)
  end
end
