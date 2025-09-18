require "test_helper"

class Fs::ValidateMessageDraftResultJobTest < ActiveJob::TestCase
  test "message draft validation result is OK without any errors/warnings/diffs if FS API returns OK" do
    outbox_message = messages(:fs_accountants_outbox)
    url = "https://fsapi.test/submissions/#{outbox_message.id}"

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      :status => 200,
      :body => {
        'result' => 'OK'
      }
    },
    [url]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::ValidateMessageDraftResultJob.new.perform(outbox_message, url)
      assert_equal 'OK', outbox_message.metadata['validation_errors']['result']
      assert_equal [], outbox_message.metadata['validation_errors']['errors']
      assert_equal [], outbox_message.metadata['validation_errors']['warnings']
      assert_equal [], outbox_message.metadata['validation_errors']['diff']
    end
  end

  test "message draft validation result is OK without any errors/warnings if FS API returns WARN with only diffs" do
    outbox_message = messages(:fs_accountants_outbox)
    url = "https://fsapi.test/submissions/#{outbox_message.id}"

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      :status => 200,
      :body => {
        'result' => 'WARN',
        'problems' => [
          {
            'message' => 'Some XML diff',
            'level' => 'diff'
          }
        ]
      }
    },
    [url]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::ValidateMessageDraftResultJob.new.perform(outbox_message, url)
      assert_equal 'OK', outbox_message.metadata['validation_errors']['result']
      assert_equal [], outbox_message.metadata['validation_errors']['errors']
      assert_equal [], outbox_message.metadata['validation_errors']['warnings']
      assert_equal ['Some XML diff'], outbox_message.metadata['validation_errors']['diff']
    end
  end

  test "message draft validation result is WARN with warnings if FS API returns warnings" do
    outbox_message = messages(:fs_accountants_outbox)
    url = "https://fsapi.test/submissions/#{outbox_message.id}"

    fs_api = Minitest::Mock.new
    fs_api.expect :get_location, {
      :status => 200,
      :body => {
        'result' => 'WARN',
        'problems' => [
          {
            'message' => "Hodnota v poli '04' vo výške 20% prislúcha k základu dane z poľa '03' (cca. 15139.98) ak je zadaný niektorý  z rokov 2021 až 2024. Ak je zadaný rok 2025 a viac, tak hodnota v poli '04' vo výške 23% prislúcha k základu dane z poľa '03' (cca. 17410.98)'",
            'level' => 'warning'
          }
        ]
      }
    },
    [url]

    FsEnvironment.fs_client.stub :api, fs_api do
      Fs::ValidateMessageDraftResultJob.new.perform(outbox_message, url)
      assert_equal 'WARN', outbox_message.metadata['validation_errors']['result']
      assert_equal [], outbox_message.metadata['validation_errors']['errors']
      assert_equal ["Hodnota v poli '04' vo výške 20% prislúcha k základu dane z poľa '03' (cca. 15139.98) ak je zadaný niektorý  z rokov 2021 až 2024. Ak je zadaný rok 2025 a viac, tak hodnota v poli '04' vo výške 23% prislúcha k základu dane z poľa '03' (cca. 17410.98)'"], outbox_message.metadata['validation_errors']['warnings']
      assert_equal [], outbox_message.metadata['validation_errors']['diff']
    end
  end
end
