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
# JSON responses adopt the Rails 8.1 defaults. API consumers must parse them as
# JSON rather than embed the response body directly into HTML or JavaScript.
