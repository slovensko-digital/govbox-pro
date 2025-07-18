require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can read message" do
    message = messages(:ssd_main_general_one)

    get "/api/messages/#{message.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal message.id, json_response["id"]
    assert_equal message.uuid, json_response["uuid"]
    assert_equal message.title, json_response["title"]
    assert_equal message.sender_name, json_response["sender_name"]
    assert_equal message.recipient_name, json_response["recipient_name"]
    assert_equal message.delivered_at, Time.zone.parse(json_response["delivered_at"])
    assert_equal message.metadata["status"], json_response["status"]
    assert_equal message.tags.first.name, json_response["tags"][0]
    assert_equal message.tags.second.name, json_response["tags"][1]
    message.objects.each do |object|
      assert_equal object.name, json_response["objects"][0]["name"]
      assert_equal object.mimetype, json_response["objects"][0]["mimetype"]
      assert_equal object.object_type, json_response["objects"][0]["object_type"]
      assert_in_delta object.updated_at, Time.zone.parse(json_response["objects"][0]["updated_at"]), 0.001
      assert_equal object.is_signed, json_response["objects"][0]["is_signed"]
      assert_equal object.message_object_datum.blob, Base64.decode64(json_response["objects"][0]["data"])
    end
  end

  test "ignores diff in message metadata" do
    @tenant = tenants(:solver)
    message = messages(:solver_draft_with_diff)

    get "/api/messages/#{message.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "OK", json_response["metadata"]["validation_errors"]["result"]
    assert_equal [], json_response["metadata"]["validation_errors"]["warnings"]
    assert_equal [], json_response["metadata"]["validation_errors"]["errors"]
    assert_not json_response["metadata"]["validation_errors"].has_key?("diff")
  end

  test "can not read nonexisting message" do
    message = messages(:ssd_main_general_one)
    message_id = message.id
    message.destroy!

    get "/api/messages/#{message_id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "can not read message from other tenant" do
    get "/api/messages/#{messages(:solver_main_delivery_notification_one).id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "can search message by UUID" do
    message = messages(:ssd_main_general_one)

    get "/api/messages/search", params: { uuid: message.uuid, token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal message.id, json_response["id"]
    assert_equal message.uuid, json_response["uuid"]
    assert_equal message.title, json_response["title"]
    assert_equal message.sender_name, json_response["sender_name"]
    assert_equal message.recipient_name, json_response["recipient_name"]
    assert_equal message.delivered_at, Time.zone.parse(json_response["delivered_at"])
    assert_equal message.metadata["status"], json_response["status"]
    message.objects.each do |object|
      assert_equal object.name, json_response["objects"][0]["name"]
      assert_equal object.mimetype, json_response["objects"][0]["mimetype"]
      assert_equal object.object_type, json_response["objects"][0]["object_type"]
      assert_in_delta object.updated_at, Time.zone.parse(json_response["objects"][0]["updated_at"]), 0.001
      assert_equal object.is_signed, json_response["objects"][0]["is_signed"]
      assert_equal object.message_object_datum.blob, Base64.decode64(json_response["objects"][0]["data"])
    end
  end

  test "can sync messages" do
    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response.pluck("id"), @tenant.messages.first.id
  end

  test "can not read first message with offset" do
    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair), last_id: @tenant.messages.first.id }, as: :json

    json_response = JSON.parse(response.body)
    assert_not_includes json_response.pluck("id"), @tenant.messages.first.id
    assert_includes json_response.pluck("id"), @tenant.messages.second.id
  end

  test "can destroy message draft" do
    message = messages(:ssd_main_general_draft_one)

    delete "/api/messages/#{message.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
  end

  test "returns not found if trying to destroy non-existing message draft" do
    delete "/api/messages/123", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "returns unprocessable entity if trying to destroy non-destroyable message" do
    message = messages(:ssd_main_general_one)

    delete "/api/messages/#{message.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :unprocessable_entity
  end
end
