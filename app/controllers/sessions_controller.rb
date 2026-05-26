class SessionsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_before_action :set_menu_context
  layout 'login'

  def login
    return unless params[:ssd_trial].present? && valid_return_url?(params[:return_url])

    session[:ssd_trial_return_url] = params[:return_url]
  end

  def trial_login
    return unless params[:ssd_trial].present? && valid_return_url?(params[:return_url])

    session[:ssd_trial_return_url] = params[:return_url]
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

  private

  ALLOWED_RETURN_HOSTS = ENV.fetch('SSD_TRIAL_RETURN_URL_ALLOWLIST', '').split(/\s*,\s*/).freeze

  def valid_return_url?(url)
    return false if url.blank?

    uri = URI.parse(url.to_s)
    return true if uri.host.nil? && uri.scheme.nil?

    %w[http https].include?(uri.scheme) && ALLOWED_RETURN_HOSTS.include?(uri.host)
  rescue URI::InvalidURIError
    false
  end
end
