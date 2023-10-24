# == Schema Information
#
# Table name: automation_rules
#
#  id                                          :integer          not null, primary key
#  name                                        :string
#  trigger_event                               :string
#  tenant_id                                   :integer          not null
#  user_id                                     :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

module Automation
  class Rule < ApplicationRecord
    belongs_to :tenant
    belongs_to :user
    has_many :conditions,
             class_name: 'Automation::Condition',
             dependent: :destroy,
             foreign_key: :automation_rule_id,
             inverse_of: :automation_rule
    has_many :actions,
             class_name: 'Automation::Action',
             dependent: :destroy,
             foreign_key: :automation_rule_id,
             inverse_of: :automation_rule

    accepts_nested_attributes_for :conditions, :actions, allow_destroy: true

    def run!(thing, _event)
      return unless conditions_met?(thing)

      actions.each { |action| action.run!(thing) }
    end

    def conditions_met?(thing)
      conditions.each { |condition| return false unless condition.satisfied?(thing) }
      true
    end

    def nested_update_with_cast(attributes)
      transaction do
        recast_conditions(attributes)
        recast_actions(attributes)
        reload
        update(attributes)
      end
    end

    def recast_conditions(attributes)
      attributes['conditions_attributes'].each do |_index, condition|
        next if condition['id'].blank?

        old_condition = conditions.find(condition['id'])
        old_condition.update_columns(type: condition['type']) if old_condition.type != condition['type']
      end
    end

    def recast_actions(attributes)
      attributes['actions_attributes'].each do |_index, action|
        next if action['id'].blank?

        old_action = actions.find(action['id'])
        old_action.update_columns(type: action['type']) if old_action.type != action['type']
      end
    end
  end
end
