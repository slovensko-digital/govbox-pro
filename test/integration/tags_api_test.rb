require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can add not existing tag" do
    thread = message_threads(:ssd_main_general)
    post "/api/message_threads/#{thread.id}/tags", params: { tags: ["Non-existing tag name"], token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_includes thread.tags, thread.tags.find_by(name: "Non-existing tag name")
  end

  test "can add tags" do
    thread = message_threads(:ssd_main_general)
    tag1 = thread.tags.first
    tag2 = thread.tags.second
    tag3 = thread.tags.third
    thread.tags.delete(tag1)
    thread.tags.delete(tag2)
    assert_not_includes thread.tags, tag1
    assert_not_includes thread.tags, tag2
    unknown_tag_name = 'Unknown tag'
    post "/api/message_threads/#{thread.id}/tags", params: { tags: [tag1.name, tag2.name, tag3.name, unknown_tag_name], token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_includes thread.tags, tag1
    assert_includes thread.tags, tag2
    assert_includes thread.tags, thread.tags.find_by(name: unknown_tag_name)
  end

  test "can remove tags" do
    thread = message_threads(:ssd_main_general)
    tag1 = thread.tags.first
    tag2 = thread.tags.second
    assert_includes thread.tags, tag1
    assert_includes thread.tags, tag2
    unknown_tag_name = 'Unknown tag'
    delete "/api/message_threads/#{thread.id}/tags", params: { tags: [tag1.name, tag2.name, unknown_tag_name], token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_not_includes thread.tags, tag1
    assert_not_includes thread.tags, tag2
  end
end
