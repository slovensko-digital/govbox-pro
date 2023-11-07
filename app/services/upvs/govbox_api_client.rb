class Upvs::GovboxApiClient
  def initialize(host: ENV.fetch('GB_API_URL'))
    @host = host
  end

  def api(box)
    Upvs::GovboxApi.new(@host, box: box)
  end
end
