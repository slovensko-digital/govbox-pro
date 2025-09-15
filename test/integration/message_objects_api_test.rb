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
    assert_equal "application/pdf", response.headers["content-type"]
    assert_equal "download; filename=\"MyString.pdf\"; filename*=UTF-8''MyString.pdf", response.headers["content-disposition"]
    assert_equal "%PDF-1.4", response.body.first(8)
  end

  test "responses with not found unless object downloadable as PDF" do
    message_object = message_objects(:ssd_main_general_one_attachment)

    get "/api/message_objects/#{message_object.id}/pdf", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end
end
