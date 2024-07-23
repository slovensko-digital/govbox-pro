require "test_helper"

class Automation::WebhookTest < ActiveSupport::TestCase
  test "should POST the url with correct payload when fired" do
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

    assert_mock downloader
  end
end
