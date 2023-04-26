module Authenticable
  SESSION_TIMEOUT = 20.minutes

  def authenticate_user
    if skip_authentication? || valid_session?(session)
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
    else
      session[:after_login_path] = request.fullpath unless request.path == login_path
      binding.pry
      redirect_to login_path
    end
  end

  def create_session
    user = User.find_by(email: auth_hash.info.email)

    if user
      session[:user_id] = user.id
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
      redirect_to session[:after_login_path] || default_after_login_path
    else
      render html: 'Not authorized', status: :forbidden
    end
  end

  def valid_session?(session)
    session[:login_expires_at].try(:to_time).present? && session[:login_expires_at].to_time > Time.current
  end

  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def skip_authentication?
    Rails.env.development? || Rails.env.test?
  end

  def login_path
    auth_path
  end

  def default_after_login_path
    root_path
  end
end
