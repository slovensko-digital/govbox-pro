require "test_helper"

class Fs::DownloadSentMessageRelatedMessagesJobTest < ActiveJob::TestCase
  test "raises error if no related messages for outbox_message" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_received_messages, {
      "count" => 0,
      "messages" => []
    },
    **{sent_message_id: outbox_message.metadata['fs_message_id'], page: 1, count: 25, from: nil, to: nil}

    fs_api.expect :fetch_received_messages, {
      "count" => 0,
      "messages" => []
    },
    **{sent_message_id: outbox_message.metadata['fs_message_id'], page: 1, count: 25, from: nil, to: nil, obo: "obo_without_delegate"}

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_raise(Fs::DownloadSentMessageRelatedMessagesJob::MissingRelatedMessagesError) do
        Fs::DownloadSentMessageRelatedMessagesJob.new.perform(outbox_message)
      end
    end
  end

  test "does not raise error if related messages for outbox_message found with obo without delegate" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_received_messages, {
      "count" => 0,
      "messages" => []
    },
    **{sent_message_id: outbox_message.metadata['fs_message_id'], page: 1, count: 25, from: nil, to: nil}

    fs_api.expect :fetch_received_messages, {
      "count" => 1,
      "messages" => [
        {
          "message_id" => "12345"
        }
      ]
    },
    **{sent_message_id: outbox_message.metadata['fs_message_id'], page: 1, count: 25, from: nil, to: nil, obo: "obo_without_delegate"}

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_enqueued_with(job: Fs::DownloadReceivedMessageJob) do
        Fs::DownloadSentMessageRelatedMessagesJob.new.perform(outbox_message)
      end
    end
  end
end
