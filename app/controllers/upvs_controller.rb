class UpvsController < ActionController::API
  include Authentication
  skip_before_action :authenticate

  def login
    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    user_uuid = response.attributes["Subject.UPVSIdentityID"]

    Current.user = User.find_by(uuid: user_uuid)

    create_session(user_uuid: user_uuid)
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
