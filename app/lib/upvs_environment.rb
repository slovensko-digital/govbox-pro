module UpvsEnvironment
  extend self

  def upvs_api(box)
    @upvs_api ||= if box.api_connection.is_a?(Govbox::ApiConnection) || box.api_connection.is_a?(Govbox::ApiConnectionWithOboSupport)
      Upvs::GovboxApiClient.new.api(box)
    elsif  box.api_connection.is_a?(SkApi::ApiConnectionWithOboSupport)
      Upvs::SkApiClient.new.api(box)
    end
  end
end
