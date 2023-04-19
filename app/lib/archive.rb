class Archive
  def self.new(environment: Rails.env, name: "archive")
    case environment
    when "development"
      NoArchive.new(name)
    when "test"
      NoArchive.new(name)
    when "staging"
      # TODO
    when "production"
      # TODO
    else
      raise
    end
  end

  def self.resolve_name(**options)
    new(options).name
  end
end
