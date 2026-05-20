module Dev
  class MockController < ApplicationController
    include Authentication
    skip_before_action :authenticate
    skip_after_action :verify_authorized

    def saml_callback
      return_url = params[:return_url]

      t = Time.now.to_i
      saml_identifier = "dev-saml-id-#{t}"
      username = "Dev User #{t}"

      payload = { saml_identifier: saml_identifier, username: username, exp: 5.minutes.from_now.to_i }
      token = JWT.encode(payload, ENV['SSD_TRIAL_SHARED_SECRET'], 'HS256')

      uri = URI.parse(return_url.to_s)
      new_query_ar = URI.decode_www_form(uri.query || '')
      new_query_ar << ["token", token]
      uri.query = URI.encode_www_form(new_query_ar)

      redirect_to uri.to_s
    end
  end
end