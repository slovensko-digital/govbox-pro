require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  test "can read thread" do
    thread = message_threads(:ssd_main_general)
    get "/api/threads/#{thread.id}", params: {}, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_includes json_response["tags"], "Finance"
    assert_includes json_response["tags"], "Legal"
    # TODO: Su tu len relative path. Ako to chceme?
    assert_includes json_response["messages"], message_path(thread.messages.first)
  end

  test "can not read nonexisting thread" do
    thread_id = 1
    thread_id += 1 while MessageThread.exists?(thread_id)
    get "/api/threads/#{thread_id}", params: {}, as: :json
    assert_response :not_found
  end
end
