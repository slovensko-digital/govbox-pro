class SessionsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_before_action :set_menu_context
  layout 'login'

  def login; end

  def no_account
    @no_account_trial_enabled = no_account_trial_enabled?
  end

  def trial_login
    return unless params[:ssd_trial].present? && valid_return_url?(params[:return_url])

    session[:ssd_trial_return_url] = params[:return_url]
    @ssd_trial_relay_state = Rails.application.message_verifier(:ssd_trial_return_url).generate(
      params[:return_url],
      expires_in: 15.minutes
    )
  end

  def create
    Current.user = User.find_by(email: auth_hash.info.email)

    create_session
    EventBus.publish(:user_logged_in, Current.user) if Current.user
  end

  def destroy
    EventBus.publish(:user_logged_out, User.find_by(id: session[:user_id])) if session[:user_id]

    redirect_to upvs_logout_path and return if session[:upvs_login]

    clean_session

    redirect_to root_path
  end

  def failure
    render html: "Authorization failed (#{request.params["message"]})", status: :forbidden
  end

  def no_account_trial
    return redirect_to no_account_sessions_path(saml_identifier: params[:saml_identifier], username: params[:username]) unless no_account_trial_enabled?

    saml_identifier = params[:saml_identifier]
    username = params[:username]

    return redirect_to no_account_sessions_path(saml_identifier: saml_identifier, username: username) if saml_identifier.blank? || username.blank?

    token = JWT.encode(
      {
        saml_identifier: saml_identifier,
        username: username,
        exp: 5.minutes.from_now.to_i
      },
      ENV.fetch('SSD_TRIAL_SHARED_SECRET'),
      'HS256'
    )

    uri = URI.parse(no_account_trial_return_url)
    uri.query = URI.encode_www_form(URI.decode_www_form(uri.query.to_s).append(['token', token]))

    redirect_to uri.to_s, allow_other_host: true
  end

  private

  def no_account_trial_enabled?
    no_account_trial_return_url.present? && ENV.fetch('SSD_TRIAL_SHARED_SECRET', '').present?
  end

  def no_account_trial_return_url
    ENV.fetch('SSD_NO_ACCOUNT_TRIAL_RETURN_URL', '').presence
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
end
