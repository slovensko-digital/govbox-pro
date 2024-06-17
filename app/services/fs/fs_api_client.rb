class Fs::FsApiClient
  def initialize(host: ENV.fetch('FS_API_URL'))
    @host = host
  end

  def api(api_connection: nil, box: nil)
    Fs::Api.new(@host, api_connection: api_connection, box: box)
  end
end
