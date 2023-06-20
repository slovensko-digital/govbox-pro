module Automation
  class Rule < ApplicationRecord
    belongs_to :tenant
    belongs_to :user
    has_many :conditions, class_name: 'Automation::Condition', dependent: :destroy, foreign_key: :automation_rule_id, inverse_of: :automation_rule
    has_many :actions, class_name: 'Automation::Action', dependent: :destroy, foreign_key: :automation_rule_id, inverse_of: :automation_rule

    def run!(thing, event)
      Current.tenant.automation_rules.where(trigger_event: event).each do |rule|
        rule.conditions.each do |condition|
          # TODO - tento break je malo?
          break unless condition.satisfied?(thing)
        end
        rule.actions.each do |action|
          action.run!(thing)
        end
      end
    end
  end
end
