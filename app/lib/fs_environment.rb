module FsEnvironment
  extend self

  def fs_client
    @fs_client ||= Fs::FsApiClient.new
  end
end
