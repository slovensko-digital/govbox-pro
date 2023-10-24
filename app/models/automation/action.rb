# == Schema Information
#
# Table name: automation_actions
#
#  id                                          :integer          not null, primary key
#  type                                        :string
#  params                                      :jsonb
#  automation_rule_id                          :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
    belongs_to :action_object, polymorphic: true, optional: true
    attr_accessor :delete_record

    def tag_list
      automation_rule.tenant.tags.pluck(:name, :id)
    end
  end

  class AddTagAction < Automation::Action
    def run!(thing)
      tag = action_object
      return if thing.thread.tenant != tag.tenant

      thing.tags << tag if tag && !thing.tags.include?(tag)
    end
  end

  class AddMessageThreadTagAction < Automation::Action
    def run!(thing)
      tag = action_object
      return if thing.tenant != tag.tenant

      object = if defined? thing.thread
                 thing.thread
               else
                 thing
               end
      object.tags << tag if tag && !object.tags.include?(tag)
    end
  end
end
