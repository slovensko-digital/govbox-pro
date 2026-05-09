# == Schema Information
#
# Table name: automation_rules
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  trigger_event :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tenant_id     :bigint           not null
#  user_id       :bigint
#
module Automation
  class Rule < ApplicationRecord
    include AuditableEvents

    belongs_to :tenant
    belongs_to :user, optional: true
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

    def run!(thing, event)
      return unless conditions_met?(thing)

      actions.each { |action| action.run!(thing, event) }
    end

    def conditions_met?(thing)
      conditions.each { |condition| return false unless condition.satisfied?(thing) }
      true
    end

    def update(attributes)
      transaction do
        recast_conditions(attributes)
        recast_actions(attributes)
        reload
        super(attributes)
      end
    end

    def recast_conditions(attributes)
      attributes['conditions_attributes']&.each do |_index, condition|
        next if condition['id'].blank?

        old_condition = conditions.find(condition['id'])
        old_condition.update_columns(type: condition['type']) if old_condition.type != condition['type']
      end
    end

    def recast_actions(attributes)
      attributes['actions_attributes']&.each do |_index, action|
        next if action['id'].blank?

        old_action = actions.find(action['id'])
        old_action.update_columns(type: action['type']) if old_action.type != action['type']
      end
    end
  end
end
