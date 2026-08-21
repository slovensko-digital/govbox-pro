# == Schema Information
#
# Table name: automation_webhooks
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint           not null
#
module Automation
  class Webhook < ApplicationRecord
    belongs_to :tenant
    has_many :automation_actions, class_name: "Automation::Action", as: :action_object, dependent: :restrict_with_error

    validates_presence_of :name, :url
    validate :url_must_be_public_https, unless: -> { Rails.env.development? }

    def fire!(message, event, timestamp, downloader: Faraday)
      data = {
        type: "#{message.class.name.underscore}.#{event}",
        timestamp: timestamp,
        data: {
          message_id: message.id,
          message_thread_id: message.thread.id
        }
      }.to_json

      downloader.post url, data, content_type: 'application/json'
    end

    private

    def url_must_be_public_https
      errors.add(:url, :not_public_https) if url.present? && !public_https_url?
    end

    def public_https_url?
      return false unless url.to_s.match?(/\A#{URI::DEFAULT_PARSER.make_regexp("https")}\z/o)

      host = URI.parse(url).host
      return false if host.blank?

      addresses = Resolv.getaddresses(host)
      addresses.any? && addresses.all? do |address|
        ip = IPAddr.new(address).native
        !ip.loopback? && !ip.private? && !ip.link_local? && !ip.to_i.zero?
      end
    end
  end
end
