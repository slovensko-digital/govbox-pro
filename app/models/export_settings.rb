# frozen_string_literal: true

# Value object around the JSONB `Export#settings` hash, so the export settings
# form can be rendered with the standard Rails form helpers instead of
# hand-composing check_box_tag + hidden_field_tag pairs.
class ExportSettings
  # Hash-like reader that answers arbitrary keys (e.g. `by_form["DPHv20"]`),
  # letting the form builder read dynamic per-form / per-type settings.
  class Group
    def initialize(hash)
      @hash = hash || {}
    end

    def [](key) = @hash[key]

    def each_pair(&block) = @hash.each_pair(&block)

    def to_h = @hash

    def method_missing(name, *args)
      return @hash[name.to_s] if args.empty?

      super
    end

    def respond_to_missing?(name, include_private = false)
      @hash.key?(name.to_s) || super
    end
  end

  def initialize(hash)
    @hash = (hash || {}).deep_stringify_keys
  end

  def to_h = @hash

  def merge(attributes)
    self.class.new(@hash.deep_merge((attributes || {}).to_h))
  end

  def summary = @hash["summary"]
  def messages = @hash["messages"]
  def pdf = @hash["pdf"]
  def default = @hash["default"]
  def message_direction = @hash["message_direction"].presence || "all"
  def delivered_at_from = @hash["delivered_at_from"]
  def delivered_at_to = @hash["delivered_at_to"]

  def by_form = Group.new(@hash["by_form"])
  def by_type = Group.new(@hash["by_type"])
  def templates = Group.new(@hash["templates"])
end
