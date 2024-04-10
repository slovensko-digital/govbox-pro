class ApiController < ActionController::API
  include LocaleConcern
  before_action :authenticate_user
  before_action :set_sk_locale
  around_action :wrap_in_request_logger

  rescue_from JWT::DecodeError do |error|
    if error.message == 'Nil JSON web token'
      render_bad_request(RuntimeError.new(:no_credentials))
    else
      # key = error.message == 'obo' ? "obo : :credentials
      render_unauthorized(error.message)
    end
  end

  rescue_from Exception, with: :render_internal_server_error
  rescue_from RestClient::Exceptions::Timeout, with: :render_request_timeout
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ArgumentError, with: :render_unprocessable_entity

  private

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def raise_with_resource_details(error = $!, resource, id, **options)
    error.resource = [resource, options.merge(id: id)] if error.respond_to?(:resource=)
    raise error
  end

  def log_request(error = nil)
    exception_wrapper = ActionDispatch::ExceptionWrapper.new(nil, error) if error
    ApiRequest.create!(
      ip_address: request.ip,
      authenticity_token: authenticity_token,
      endpoint_method: request.method,
      endpoint_path: request.path,
      response_status: error ? exception_wrapper.status_code : response.code
    )
  end

  def wrap_in_request_logger
    yield
  rescue Exception => e
    log_request(e)
    raise e
  else
    log_request
  end

  def render_bad_request(exception)
    render status: :bad_request, json: { message: exception.message }
  end

  def render_unauthorized(key = "credentials")
    headers['WWW-Authenticate'] = 'Token realm="API"'
    render status: :unauthorized, json: { message: "Unauthorized " + key }
  end

  def render_unpermitted_param(**_options)
    render status: :unprocessable_entity, json: { message: "Unprocessable entity" }
  end

  def render_forbidden_no_key
    render status: :forbidden, json: { message: "Forbidden" }
  end

  def render_forbidden(_key, **_options)
    render status: :forbidden, json: { message: "Forbidden" }
  end

  def render_not_found(_key, **_options)
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

  def render_unprocessable_entity(message)
    render status: :unprocessable_entity, json: { message: message }
  end
end
