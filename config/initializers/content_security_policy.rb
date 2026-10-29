# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  # Import maps and their module entrypoints are inline scripts.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  upvs_login_url = ENV.fetch("UPVS_ENV", "fix") == "prod" ? "https://prihlasenie.slovensko.sk" : "https://prihlasenie.upvsfix.gov.sk"
  no_account_trial_origin = -> { ENV["SSD_NO_ACCOUNT_TRIAL_RETURN_URL"].presence&.then { |url| URI(url).origin } }

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.form_action :self,
                       *("https://accounts.google.com" if ENV["GOOGLE_CLIENT_ID"].present?),
                       *("https://login.microsoftonline.com" if ENV["AZURE_APPLICATION_CLIENT_ID"].present?),
                       *(upvs_login_url if ENV["UPVS_SSO_SUBJECT"].present?),
                       no_account_trial_origin
    policy.frame_ancestors :self
    policy.frame_src   :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :data,
                       *("https://*.googleusercontent.com" if ENV["GOOGLE_CLIENT_ID"].present?)
    policy.connect_src :self, "http://localhost:37200", "https://loopback.autogram.slovensko.digital:37200"
  end
end
