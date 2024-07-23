# == Schema Information
#
# Table name: automation_actions
#
#  id                 :bigint           not null, primary key
#  action_object_type :string
#  type               :string
#  value              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  action_object_id   :bigint
#  automation_rule_id :bigint           not null
#
module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
    belongs_to :action_object, polymorphic: true, optional: true
    attr_accessor :delete_record

    ACTION_LIST = ['Automation::AddMessageThreadTagAction', 'Automation::FireWebhookAction'].freeze

    def tag_list
      automation_rule.tenant.tags.pluck(:name, :id)
    end
  end

  # deprecated, fully replaced by AddMessageThreadTagAction
  class AddTagAction < Action
  end

  class AddMessageThreadTagAction < Action
    def run!(thing, _event)
      tag = action_object
      return if thing.tenant != tag.tenant

      object = if thing.respond_to? :thread
                 thing.thread
               else
                 thing
               end
      object.tags << tag if tag && object.tags.exclude?(tag)
    end
  end

  class FireWebhookAction < Action
    def run!(thing, event)
      webhook = action_object
      return unless thing.tenant == webhook.tenant

      FireWebhookJob.perform_later(webhook, thing, event, DateTime.now)
    end
  end
end
