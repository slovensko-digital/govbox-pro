class WebpushJob < ApplicationJob
  def perform(title, body, url, user)
    icon_url = ActionController::Base.helpers.asset_url("SD_icon.png")
    user.push_endpoints.each do |endpoint|
      WebPush.payload_send(
        endpoint: endpoint.endpoint,
        message: { title: title, options: { body: body, icon: icon_url, data: { url: url } } }.to_json,
        p256dh: endpoint.p256dh,
        auth: endpoint.auth,
        ttl: 7 * 24 * 60 * 60,
        vapid: {
          subject: ENV.fetch("DOMAIN_NAME"),
          public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
          private_key: ENV.fetch("VAPID_PRIVATE_KEY")
        }
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      endpoint.destroy!
    end
  end
end
