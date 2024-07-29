require "test_helper"

class Automation::FireWebhookJobTest < ActiveJob::TestCase
  test "should call webhook.fire! and POST the url with correct payload" do
    message1 = messages(:ssd_main_draft)
    event = :event
    timestamp = DateTime.now
    data = {
      type: "#{message1.class.name.underscore}.#{event}",
      timestamp: timestamp,
      data: {
        message_id: message1.id,
        message_thread_id: message1.thread.id
      }
    }.to_json
    webhook = automation_webhooks(:one)

    downloader = Minitest::Mock.new
    downloader.expect :post, true, [webhook.url, data], content_type: 'application/json'

    webhook.fire! message1, event, timestamp, downloader: downloader

    Faraday.stub :post, downloader do
      Automation::FireWebhookJob.new.perform(webhook, message1, event, timestamp)
    end

    assert_mock downloader
  end
end
