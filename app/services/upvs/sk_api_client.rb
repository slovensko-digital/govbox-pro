class Upvs::SkApiClient
  def initialize(host: ENV.fetch('SK_API_URL'))
    @host = host
  end

  def api(box: nil, api_connection: nil)
    Upvs::SkApi.new(@host, box: box, api_connection: api_connection)
  end
end
