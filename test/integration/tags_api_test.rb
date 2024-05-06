require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can add tag" do
    thread = message_threads(:ssd_main_general)
    tag = tags(:ssd_finance)
    thread.tags.delete(tag)
    post "/api/message_threads/#{thread.id}/tags", params: { tag: { name: tag.name }, token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_includes thread.tags, tag
  end
  test "can add already associated tag" do
    thread = message_threads(:ssd_main_general)
    tag = tags(:ssd_finance)
    assert_includes thread.tags, tag
    post "/api/message_threads/#{thread.id}/tags", params: { tag: { name: tag.name }, token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_includes thread.tags, tag
  end

  test "can not add not existing tag" do
    thread = message_threads(:ssd_main_general)
    post "/api/message_threads/#{thread.id}/tags", params: { tag: { name: "Non-existing tag name" }, token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "can remove tag" do
    thread = message_threads(:ssd_main_general)
    tag = thread.tags.first
    assert_includes thread.tags, tag
    delete "/api/message_threads/#{thread.id}/tags", params: { tag: { name: tag.name }, token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_not_includes thread.tags, tag
  end

  test "can batch add tags" do
    thread = message_threads(:ssd_main_general)
    tag1 = thread.tags.first
    tag2 = thread.tags.second
    tag3 = thread.tags.third
    thread.tags.delete(tag1)
    thread.tags.delete(tag2)
    assert_not_includes thread.tags, tag1
    assert_not_includes thread.tags, tag2
    unknown_tag_name = 'Unknown tag'
    post "/api/message_threads/#{thread.id}/tags/batch_add", params: { tags: [tag1.name, tag2.name, tag3.name, unknown_tag_name], token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response["result"], { tag1.name => "added" }
    assert_includes json_response["result"], { tag3.name => "skipped" }
    assert_includes json_response["result"], { unknown_tag_name => "not_found" }
    assert_includes thread.tags, tag1
    assert_includes thread.tags, tag2
  end

  test "can batch remove tags" do
    thread = message_threads(:ssd_main_general)
    tag1 = thread.tags.first
    tag2 = thread.tags.second
    assert_includes thread.tags, tag1
    assert_includes thread.tags, tag2
    unknown_tag_name = 'Unknown tag'
    delete "/api/message_threads/#{thread.id}/tags/batch_remove", params: { tags: [tag1.name, tag2.name, unknown_tag_name], token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response["result"], { tag1.name => "removed" }
    assert_includes json_response["result"], { unknown_tag_name => "skipped" }
    assert_not_includes thread.tags, tag1
    assert_not_includes thread.tags, tag2
  end
end
