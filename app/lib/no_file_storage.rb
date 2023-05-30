class NoFileStorage
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def store(scope, name, content)
    path = File.join(Rails.root, 'storage', scope, name)
    create_dir_if_not_exists(path)
    File.write(path, content)

    path
  end

  def exists?(scope, date, path)
    false
  end

  private

  def create_dir_if_not_exists(path)
    dirname = File.dirname(path)
    FileUtils.mkdir_p(dirname)unless File.directory?(dirname)
  end
end
