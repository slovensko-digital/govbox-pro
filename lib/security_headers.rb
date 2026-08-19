class SecurityHeaders
  def initialize(app)
    @app = app
    @headers = ActionDispatch::Response.default_headers
      .merge(ActionDispatch::Constants::CONTENT_SECURITY_POLICY => Rails.application.config.content_security_policy&.build)
      .compact
      .transform_keys(&:downcase)
  end

  def call(env)
    status, headers, body = @app.call(env)

    @headers.each { |name, value| headers[name] ||= value }

    [status, headers, body]
  end
end
