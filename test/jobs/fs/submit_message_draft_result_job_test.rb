require "test_helper"

class Fs::SubmitMessageDraftResultJobTest < ActiveJob::TestCase
  test "saves submit_error_message when response contains 'používateľ nemá'" do
    message_draft = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      status: 400,
      body: { "message" => "používateľ nemá prístup k službe" }
    }, ["location123"]

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_raises(RuntimeError) do
        Fs::SubmitMessageDraftResultJob.new.perform(message_draft, "location123")
      end

      assert_equal "submit_fail", message_draft.metadata["status"]
      assert_equal "používateľ nemá prístup k službe", message_draft.metadata["submit_error_message"]
    end
  end

  test "does not save submit_error_message when response does not contain 'používateľ nemá'" do
    message_draft = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      status: 400,
      body: { "message" => "neobsahuje požadovaný text" }
    }, ["location123"]

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_raises(RuntimeError) do
        Fs::SubmitMessageDraftResultJob.new.perform(message_draft, "location123")
      end

      assert_equal "submit_fail", message_draft.metadata["status"]
      assert_nil message_draft.metadata["submit_error_message"]
    end
  end

  test "marks message as submitted when response status is 200" do
    message_draft = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      status: 200,
      body: { "sent_message_id" => "12345/2024" }
    }, ["location123"]

    FsEnvironment.fs_client.stub :api, fs_api do
      Automation::ApplyRulesForEventJob.stub :perform_later, nil do
        Fs::SubmitMessageDraftResultJob.new.perform(message_draft, "location123")
      end

      assert_equal "submitted", message_draft.reload.metadata["status"]
      assert_equal "12345/2024", message_draft.metadata["fs_message_id"]
    end
  end
end
