require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new(512)
    @tenant = tenants(:solver)
    @tenant.enable_feature(:api) unless @tenant.feature_enabled? :api
    @tenant.api_token_public_key = @key_pair.public_key
    @tenant.save
  end
  test "can read message" do
    message = messages(:ssd_main_general_one)
    get "/api/messages/#{message.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["id"], message.id
    assert json_response["uuid"], message.uuid
    assert json_response["title"], message.title
    assert json_response["sender_name"], message.sender_name
    assert json_response["recipient_name"] || "nil", message.recipient_name || "nil"
    assert json_response["delivered_at"], message.delivered_at
    assert json_response["metadata"], message.metadata
    message.objects.each do |object|
      assert json_response["objects"][0]["name"], object.name
      assert json_response["objects"][0]["mimetype"], object.mimetype
      assert json_response["objects"][0]["object_type"], object.object_type
      assert json_response["objects"][0]["updated_at"], object.updated_at
      assert json_response["objects"][0]["is_signed"], object.is_signed
      assert Base64.decode64(json_response["objects"][0]["data"]), object.message_object_datum.blob
    end
  end

  test "can not read nonexisting message" do
    message_id = 1
    message_id += 1 while Message.exists?(message_id)
    get "/api/messages/#{message_id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json
    assert_response :not_found
  end
end
