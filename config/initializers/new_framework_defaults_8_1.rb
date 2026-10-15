# JSON escaping is explicitly preserved in application.rb (HTML and U+2028/2029).
# Adopt the remaining 8.1 defaults via load_defaults:
# - remove_hidden_field_autocomplete = true (no changes to submitted values)
# - action_on_path_relative_redirect = :raise (reject unsafe redirects)
# - render_tracker = :ruby (template dependency tracking)
# - raise_on_missing_required_finder_order_columns = true (deterministic finders)
