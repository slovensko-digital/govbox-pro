require "test_helper"

class Automation::FireWebhookJobTest < ActiveJob::TestCase
  test "should discard the job instead of retrying it when the webhook url is blocked" do
    webhook = automation_webhooks(:one)
    webhook.update_column(:url, "http://127.0.0.1/hook")

    perform_enqueued_jobs do
      Automation::FireWebhookJob.perform_later(webhook, messages(:ssd_main_draft), :event, DateTime.now)
    end

    assert_equal 0, enqueued_jobs.size
  end
end
