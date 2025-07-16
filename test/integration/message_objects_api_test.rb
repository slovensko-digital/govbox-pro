require "test_helper"

class MessageObjectsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can get PDF visualization" do
    message_object = message_objects(:ssd_main_general_two_form)

    get "/api/message_objects/#{message_object.id}/pdf", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 12884, json_response["content"].size
    assert_equal 'JVBERi0xLj', json_response["content"].first(10)
  end
end
