module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  SESSION_TIMEOUT = 20.minutes

  def authenticate
    if skip_authentication? || valid_session?(session)
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
    else
      session[:after_login_path] = request.fullpath unless request.path == login_path
      redirect_to login_path
    end

    load_current_user
  end

  def create_session
    Current.user = User.find_by(email: auth_hash.info.email)

    if Current.user
      session[:user_id] = Current.user.id
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
      session[:tenant_id] = Current.user.tenant_id
      redirect_to session[:after_login_path] || default_after_login_path
    else
      render html: 'Not authorized', status: :forbidden
    end
  end

  def clean_session
    session[:user_id] = nil
    session[:login_expires_at] = nil
    session[:tenant_id] = nil
  end

  def load_current_user
    Current.user = User.find(session[:user_id]) if session[:user_id]
    Current.tenant = Tenant.find(session[:tenant_id]) if session[:tenant_id]
    Current.box = Current.tenant&.boxes&.first # TODO fix this for multiple & zero boxes
  end

  def valid_session?(session)
    session[:login_expires_at].try(:to_time).present? && session[:login_expires_at].to_time > Time.current
  end

  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def skip_authentication?
    # !Rails.env.prod?
    false
  end

  def login_path
    auth_path
  end

  def default_after_login_path
    root_path
  end
end
