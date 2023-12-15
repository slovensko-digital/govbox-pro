class Upvs::SkApiClient
  def initialize(host: ENV.fetch('SK_API_URL'))
    @host = host
  end

  def api(box)
    Upvs::SkApi.new(@host, box: box)
  end
end
