class WebpushJob < ApplicationJob
  def perform(title, body, url, user)
    icon_url = ActionController::Base.helpers.asset_url("SD_icon.png", host: ENV.fetch("DOMAIN_NAME", nil))
    user.push_endpoints.each do |endpoint|
      WebPush.payload_send(
        endpoint: endpoint.endpoint,
        message: JSON.generate({
                                 title: title,
                                 options: {
                                   body: body,
                                   icon: icon_url,
                                   data: {
                                     url: url
                                   }
                                 }
                               }),
        p256dh: endpoint.p256dh,
        auth: endpoint.auth,
        ttl: 7 * 24 * 60 * 60,
        vapid: {
          subject: "mailto:#{User.first.email}",
          public_key: ENV.fetch("VAPID_PUBLIC_KEY", nil),
          private_key: ENV.fetch("VAPID_PRIVATE_KEY", nil)
        }
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      endpoint.destroy!
    end
  end
end
