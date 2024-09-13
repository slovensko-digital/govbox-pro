module WebhooksHelper
  def webhook_action_select_options(webhooks)
    webhooks.map { |webhook| [webhook.name, webhook.id] }
  end
end
