# Adopted framework defaults for Rails 8.1 (config.load_defaults 8.1 sets all of
# the following unless noted):
#
# - action_view.remove_hidden_field_autocomplete = true (no change to submitted values)
# - action_controller.action_on_path_relative_redirect = :raise (rejects unsafe redirects)
# - action_view.render_tracker = :ruby
# - active_record.raise_on_missing_required_finder_order_columns = true
# - action_controller.escape_json_responses = false
# - active_support.escape_js_separators_in_json = false
#
# The two JSON escaping defaults are intentionally overridden back to true for
# the public API in config/application.rb. Both are deprecated in Rails 8.2, so
# revisit them there (see public/openapi.yaml and test/integration/*_api_test.rb).
