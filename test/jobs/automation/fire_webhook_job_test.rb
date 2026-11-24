require "test_helper"

class Automation::FireWebhookJobTest < ActiveJob::TestCase
  test "should retry when the webhook url responds with an error status" do
    Automation::Webhook::DEFAULT_DOWNLOADER.stub :post, Faraday::Response.new(status: 503) do
      Automation::FireWebhookJob.perform_now(automation_webhooks(:one), messages(:ssd_main_draft), :message_created, DateTime.now)
    end

    assert_enqueued_jobs 1, only: Automation::FireWebhookJob
  end

  test "should not retry when the webhook url responds with success" do
    Automation::Webhook::DEFAULT_DOWNLOADER.stub :post, Faraday::Response.new(status: 204) do
      Automation::FireWebhookJob.perform_now(automation_webhooks(:one), messages(:ssd_main_draft), :message_created, DateTime.now)
    end

    assert_no_enqueued_jobs only: Automation::FireWebhookJob
  end
end
