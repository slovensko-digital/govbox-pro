class Upvs::GovboxApiClient
  def initialize(host: ENV.fetch('GB_API_URL'))
    @host = host
  end

  def api(box)
    govbox_api_connection = box.api_connection
    obo = box.settings["obo"] if box.settings
    Upvs::GovboxApi.new(@host, api_connection: govbox_api_connection, obo: obo)
  end
end
