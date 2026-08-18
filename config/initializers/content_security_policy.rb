# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.form_action :self
    policy.frame_ancestors :self
    policy.frame_src   :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.font_src    :self
    policy.img_src     :self, :data, "https://*.googleusercontent.com"
    policy.connect_src :self, "http://localhost:37200", "https://loopback.autogram.slovensko.digital:37200"
  end
end
