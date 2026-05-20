class Fs::FsApiClient
  def initialize(host: ENV.fetch('FS_API_URL'))
    @host = host
  end

  def api(api_connection: nil, box: nil)
    Fs::Api.new(@host, api_connection: api_connection, box: box)
  end

  def admin_api
    @admin_api ||= Fs::AdminApi.new(
      @host,
      ENV.fetch('FS_ADMIN_SUB'),
      Base64.decode64(ENV.fetch('FS_ADMIN_PRIVATE_KEY_B64'))
    )
  end
end
