# == Schema Information
#
# Table name: automation_webhooks
#
#  id           :bigint           not null, primary key
#  auth         :string
#  name         :string           not null
#  request_type :string           not null
#  secret       :string
#  url          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tenant_id    :bigint           not null
#
module Automation
  class Webhook < ApplicationRecord
    belongs_to :tenant, dependent: :destroy
    has_many :automation_actions, class_name: "Automation::Action", as: :action_object, dependent: :restrict_with_error

    validates_presence_of :name, :url, :request_type

    def fire!(thing, event, timestamp)
      if request_type == 'plain'
        fire_plain_webhook
      elsif request_type == 'standard'
        fire_standard_webhook thing, event, timestamp
      else
        throw StandardError.new "Unknown webhook request type: '#{request_type}'"
      end
    end

    private

    def fire_plain_webhook
      Faraday.post url
    end

    def fire_standard_webhook(thing, event, timestamp)
      data = {
        type: "#{thing.class.name}.#{event}",
        timestamp: timestamp,
        data: standard_webhook_data(thing)
      }.to_json

      Faraday.post url, data, content_type: 'application/json'
    end

    def standard_webhook_data(thing)
      if thing.instance_of?(::MessageThread)
        {
          message_thread_id: thing.id
        }
      elsif thing.instance_of?(::Message)
        {
          message_id: thing.id,
          message_thread_id: thing.thread.id
        }
      else
        throw StandardError.new "Unsupported webhook thing object: '#{thing.class.name}'"
      end
    end
  end
end
