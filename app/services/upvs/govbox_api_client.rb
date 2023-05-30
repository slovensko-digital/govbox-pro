class Upvs::GovboxApiClient
  def initialize(host: ENV.fetch('GB_API_URL'))
    @host = host
  end

  def api(govbox_api_connection)
    Upvs::GovboxApi.new(@host, govbox_api_connection)
  end
end
