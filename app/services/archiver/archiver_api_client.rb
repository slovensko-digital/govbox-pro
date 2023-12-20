class Archiver::ArchiverApiClient
  def initialize(host: ENV['ARCHIVER_API_URL'])
    @host = host
  end

  def api
    Archiver::ArchiverApi.new(@host)
  end
end
