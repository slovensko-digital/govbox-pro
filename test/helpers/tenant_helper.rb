module TenantHelper
  def with_env_features(features_string)
    original_value = ENV.fetch('TENANT_AVAILABLE_FEATURE_FLAGS')
    ENV['TENANT_AVAILABLE_FEATURE_FLAGS'] = features_string
    yield
  ensure
    ENV['TENANT_AVAILABLE_FEATURE_FLAGS'] = original_value
  end
end
