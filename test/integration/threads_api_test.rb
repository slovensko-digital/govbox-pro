require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can read thread" do
    thread = message_threads(:ssd_main_general)

    get "/api/message_threads/#{thread.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response["tags"], "Finance"
    assert_includes json_response["tags"], "Legal"
    assert_includes json_response["messages"], api_message_url(thread.messages.first)
  end

  test "can not read nonexisting thread" do
    thread_id = 1
    thread_id += 1 while MessageThread.exists?(thread_id)

    get "/api/message_threads/#{thread_id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "can not read thread from other tenant" do
    thread = MessageThread.joins(:box).where(box: { tenant_id: tenants(:solver).id }).first

    get "/api/message_threads/#{thread.id}", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "can read thread list" do
    get "/api/message_threads", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response["message_threads"].pluck("id"), @tenant.message_threads.first.id
    assert_includes json_response["message_threads"].pluck("id"), @tenant.message_threads.last.id
  end

  test "can not read first thread with offset" do
    get "/api/message_threads", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair), offset: @tenant.message_threads.first.id }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_includes json_response["message_threads"].pluck("id"), @tenant.message_threads.first.id
    assert_includes json_response["message_threads"].pluck("id"), @tenant.message_threads.second.id
  end
end
