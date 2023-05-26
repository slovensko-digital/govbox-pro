class FileStorage
  def self.new(environment: Rails.env, name: "file_storage")
    case environment
    when "development"
      NoFileStorage.new(name)
    when "test"
      NoFileStorage.new(name)
    when "staging"
      # TODO
      NoFileStorage.new(name)
    when "production"
      # TODO
      NoFileStorage.new(name)
    else
      raise
    end
  end

  def self.resolve_name(**options)
    new(options).name
  end
end
