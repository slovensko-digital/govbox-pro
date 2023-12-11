class ApiController < ActionController::API
  include AuditableApiEvents

  before_action :authenticate_user
  around_action :wrap_in_request_logger

  rescue_from JWT::DecodeError do |error|
    if error.message == 'Nil JSON web token'
      render_bad_request(:no_credentials)
    else
      key = error.message == 'obo' ? :obo : :credentials
      render_unauthorized(key)
    end
  end

  rescue_from RestClient::Exceptions::Timeout, with: :render_request_timeout
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity

  private

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def set_tenant
    @tenant = Tenant.find(params.require(:id))
  end


  def raise_with_resource_details(error = $!, resource, id, **options)
    error.resource = [resource, options.merge(id: id)] if error.respond_to?(:resource=)
    raise error
  end

  def log_request(error = nil)
    # TODO save the log somewhere
  end

  def wrap_in_request_logger
    yield
  rescue Error => error
    log_request(error) and raise(error)
  else
    log_request
  end


  def render_bad_request(key, **options)
    render status: :bad_request, json: { message: "Bad request" }
  end

  def render_unauthorized(key = :credentials)
    self.headers['WWW-Authenticate'] = 'Token realm="API"'
    render status: :unauthorized, json: { message: "Unauthorized" }
  end

  def render_unpermitted_param(**options)
    render status: :unprocessable_entity, json: { message: "Unprocessable entity" }
  end

  def render_forbidden_no_key
    render status: :forbidden, json: { message: "Forbidden" }
  end

  def render_forbidden(key, **options)
    render status: :forbidden, json: { message: "Forbidden" }
  end

  def render_not_found(key, **options)
    render status: :not_found, json: { message: "Not found" }
  end

  def render_request_timeout
    render status: :request_timeout, json: { message: "request timeout" }
  end

  def render_too_many_requests
    render status: :too_many_requests, json: { message: "Too many requests" }
  end

  def render_internal_server_error
    render status: :internal_server_error, json: { message: "Internal server error" }
  end

  def render_service_unavailable_error
    render status: :service_unavailable, json: { message: "Service unavailable" }
  end
end
