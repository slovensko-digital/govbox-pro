class Upvs::GovboxApiClient
  def initialize(host: ENV.fetch('GB_API_URL'))
    @host = host
  end

  def api(box)
    govbox_api_connection = Govbox::ApiConnection.find_by(box_id: box.id)
    Upvs::GovboxApi.new(@host, govbox_api_connection)
  end
end
