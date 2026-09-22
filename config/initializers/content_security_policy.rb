# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  upvs_login_url = ENV.fetch("UPVS_ENV", "fix") == "prod" ? "https://prihlasenie.slovensko.sk" : "https://prihlasenie.upvsfix.gov.sk"

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.form_action :self,
                       *("https://accounts.google.com" if ENV["GOOGLE_CLIENT_ID"].present?),
                       *("https://login.microsoftonline.com" if ENV["AZURE_APPLICATION_CLIENT_ID"].present?),
                       *(upvs_login_url if ENV["UPVS_SSO_SUBJECT"].present?)
    policy.frame_ancestors :self
    policy.frame_src   :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.font_src    :self
    policy.img_src     :self, :data,
                       *("https://*.googleusercontent.com" if ENV["GOOGLE_CLIENT_ID"].present?)
    policy.connect_src :self, "http://localhost:37200", "https://loopback.autogram.slovensko.digital:37200"
  end
end
