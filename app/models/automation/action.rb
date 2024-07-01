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

    ACTION_LIST = ['Automation::AddMessageThreadTagAction', 'Automation::ChangeMessageThreadTitleAction'].freeze

    def tag_list
      automation_rule.tenant.tags.pluck(:name, :id)
    end
  end

  # deprecated, fully replaced by AddMessageThreadTagAction
  class AddTagAction < Automation::Action
  end

  class AddMessageThreadTagAction < Automation::Action
    def run!(thing)
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

  class ChangeMessageThreadTitleAction < Automation::Action
    def run!(thing)
      object = if thing.respond_to? :thread
                 thing.thread
               else
                 thing
               end
      new_value = value.gsub("${title}", object.title)
      object.title = new_value
      object.save!
    end
  end
end
