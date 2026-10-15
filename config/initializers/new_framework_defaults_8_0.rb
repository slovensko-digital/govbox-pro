# load_defaults 8.0 adopts timezone-preserving to_time (:zone) and RFC-compliant
# conditional requests (action_dispatch.strict_freshness = true).
# Regexp.timeout is not set by load_defaults; adopt the generated security default.
Regexp.timeout = 1
