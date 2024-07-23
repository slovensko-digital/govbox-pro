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

    def fire!(message, event, timestamp, downloader: Faraday)
      data = {
        type: "#{message.class.name}.#{event}",
        timestamp: timestamp,
        data: {
          message_id: message.id,
          message_thread_id: message.thread.id
        }
      }.to_json

      downloader.post url, data, content_type: 'application/json'
    end
  end
end
