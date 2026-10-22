# Rails 8.1 stopped escaping HTML entities and Unicode line separators in the
# JSON renderer, because `render json:` returns an `application/json` document
# that is normally not embedded into HTML. Escaping it is not free, so the
# framework made it opt-out.
#
# This application serves a public API, whose responses used to be escaped
# before the upgrade and may be embedded into HTML by their consumers, so the
# escaping is kept. `config.action_controller.escape_json_responses = true`
# would do it, but that setting is deprecated and will have no effect in
# Rails 8.2, so the supported `escape: true` option of `render json:` is used
# instead.
module EscapedJsonResponses
  extend ActiveSupport::Concern

  def render(*args, &)
    options = args.last

    if options.is_a?(Hash) && options.key?(:json) && !options.key?(:escape)
      args = args.dup
      args[-1] = options.merge(escape: true)
    end

    super
  end
end
