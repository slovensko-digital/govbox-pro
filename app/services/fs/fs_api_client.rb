class Fs::FsApiClient
  def initialize(host: ENV.fetch('FS_API_URL'))
    @host = host
  end

  def api(box: nil)
    Fs::Api.new(@host, box: box)
  end
end
