module UpvsEnvironment
  extend self

  def upvs_client
    @upvs_client ||= Upvs::GovboxApiClient.new
  end
end
