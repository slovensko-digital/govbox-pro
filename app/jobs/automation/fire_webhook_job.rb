class Automation::FireWebhookJob < ApplicationJob
  queue_as :automation
  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform(webhook, thing, event, timestamp, downloader: Faraday)
    webhook.fire! thing, event, timestamp, downloader: downloader
  end
end
