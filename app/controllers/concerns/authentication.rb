module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  SESSION_TIMEOUT = 20.minutes

  def authenticate
    if request.path != login_path && request.get? && !turbo_frame_request?
      session[:after_login_path] = request.fullpath
    end

    if valid_session?(session)
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
    else
      redirect_to login_path
    end

    load_current_user
  end

  def create_session(user_uuid: nil)
    if Current.user
      session[:user_id] = Current.user.id
      session[:login_expires_at] = SESSION_TIMEOUT.from_now
      session[:tenant_id] = Current.user.tenant_id
      session[:user_profile_picture_url] = auth_hash.info.image
      session[:box_id] = Current.user.tenant.boxes.first.id if Current.user.tenant.boxes.one?
      session[:upvs_login] = user_uuid.present?
      redirect_to session[:after_login_path] || default_after_login_path
    else
      redirect_to no_account_sessions_path(uuid: user_uuid)
    end
  end

  def clean_session
    session[:user_id] = nil
    session[:login_expires_at] = nil
    session[:tenant_id] = nil
    session[:box_id] = nil
  end

  def load_current_user
    Current.user = User.find(session[:user_id]) if session[:user_id]
    Current.tenant = Tenant.find(session[:tenant_id]) if session[:tenant_id]
    Current.box = Current.tenant.boxes.find(session[:box_id]) if session[:box_id] # TODO handle case when box was deleted
  end

  def valid_session?(session)
    session[:login_expires_at].try(:to_time).present? && session[:login_expires_at].to_time > Time.current
  end

  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def login_path
    auth_path
  end

  def default_after_login_path
    root_path
  end
end
